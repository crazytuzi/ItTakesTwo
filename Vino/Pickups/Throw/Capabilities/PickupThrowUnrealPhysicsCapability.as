import Vino.Pickups.PickupActor;

class UPickupThrowUnrealPhysicsCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupThrowUnrealPhysicsCapability);

	APickupActor PickupOwner;
	UMeshComponent PickupMesh;
	UHazeCrumbComponent CrumbComponent;

	bool bCollisionProfileRestored;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupOwner = Cast<APickupActor>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
		PickupMesh = PickupOwner.Mesh;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PickupOwner.ThrowParams == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(PickupOwner.ThrowType != EPickupThrowType::UnrealPhysics)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(HasControl())
		{
			// Disable pickup owner's movement component
			PickupOwner.MovementComponent.Deactivate();
			PickupOwner.CollisionShape.Deactivate();

			// Make mesh root so that it moves the actor
			PickupOwner.SetRootComponent(PickupMesh);

			// Start simulating physics and set throw velocity
			PickupMesh.SetSimulatePhysics(true);
			PickupMesh.SetPhysicsLinearVelocity(PickupOwner.ThrowParams.ThrowVelocity);

			// Add random angular impulse for good measure
			FVector AngularVelocity = PickupOwner.ActorRightVector * FMath::RandRange(5.f, 300.f) + PickupOwner.ActorForwardVector * FMath::RandRange(-200.f, 200.f);
			PickupMesh.AddAngularImpulseInDegrees(AngularVelocity, NAME_None, true);
		}

		// Turn off collisions in actor (at least while it's being cast)
		PickupMesh.SetCollisionProfileName(n"PickupPhysicsThrow");
		PickupOwner.CollisionShape.SetCollisionProfileName(n"PickupPhysicsThrow");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			PickupMesh.AddForce(PickupOwner.ThrowParams.Gravity, NAME_None, true);
			CrumbComponent.LeaveMovementCrumb();

			// Restore collision profile after pickup has cleared player
			if(!bCollisionProfileRestored && !PickupActorIsOverlappingWithPlayer())
			{
				bCollisionProfileRestored = true;
				PickupMesh.SetCollisionProfileName(PickupOwner.OriginalCollisionProfile);
				PickupOwner.CollisionShape.SetCollisionProfileName(n"IgnorePlayerCharacter");
			}
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);

			FHazeFrameMovement MoveData = PickupOwner.MovementComponent.MakeFrameMovement(PickupTags::PickupThrowUnrealPhysicsCapability);
			MoveData.ApplyConsumedCrumbData(CrumbData);
			PickupOwner.MovementComponent.Move(MoveData);
		}
	}

	// Eman TODO: we probably need something fancier; just arbitrarily check velocity for now
	UFUNCTION(BlueprintOverride) const
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(PickupTags::AbortPickupFlight))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!PickupMesh.GetPhysicsLinearVelocity().IsNearlyZero(1.f))
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!PickupMesh.GetPhysicsAngularVelocityInDegrees().IsNearlyZero(1.f))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HasControl())
		{
			// Turn off simulated physics
			PickupMesh.SetSimulatePhysics(false);

			// Restore original actor's root component and set location to former pickup mesh's
			PickupOwner.SetRootComponent(PickupOwner.Root);
			PickupOwner.SetActorLocation(PickupMesh.WorldLocation);

			// Save mesh rotation to set it on actor after reactivating movement component
			FRotator PickupRotation = PickupMesh.WorldRotation;

			// Re-attach pickup mesh to root
			PickupMesh.AttachToComponent(PickupOwner.PickupRoot);

			// Re activate movement component. This will reset actor rotation, set pickup mesh former rotation!
			PickupOwner.CollisionShape.Activate();
			PickupOwner.MovementComponent.Activate();
			PickupOwner.SetActorRotation(PickupRotation);

			// Clean pickup actor throw params
			PickupOwner.ThrowParams = nullptr;
		}

		// Attach to floor actor if it contains a dynamic mesh and restore original collision profile
		// PickupFloorAttacherCapability will listen to this event
		PickupOwner.OnStoppedMovingAfterThrowEvent.Broadcast();

		// Cleanup
		bCollisionProfileRestored = false;
	}

	bool PickupActorIsOverlappingWithPlayer() const
	{
		TArray<AActor> OverlappingActors;
		PickupOwner.GetOverlappingActors(OverlappingActors, AHazePlayerCharacter::StaticClass());
		return OverlappingActors.Num() > 0;
	}
}