import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Vino.Pickups.Throw.PickupThrowComponent;
import Vino.Trajectory.TrajectoryStatics;

class UTrapezeCatcherThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::CatcherThrow);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UTrapezeComponent TrapezeComponent;

	ATrapezeActor Trapeze;
	ATrapezeMarbleActor Marble;

	FThrownActorReachedTarget MarbleReachedTrajectoryEnd;

	const float ThrowMark = 0.18f;
	float ThrowTimer;

	bool bThrowInProgress;
	bool bAssistedThrow;
	bool bMarbleReachedTrajectoryEnd;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TrapezeComponent.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		ATrapezeActor TrapezeActor = Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
		if(!TrapezeActor.bIsCatchingEnd)
			return EHazeNetworkActivation::DontActivate;

		if(!TrapezeComponent.PlayerHasMarble())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(TrapezeTags::MarbleThrow, this);

		Trapeze = Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
		Marble = TrapezeComponent.Marble;

		// Bind delegate
		MarbleReachedTrajectoryEnd.AddUFunction(this, n"OnMarbleReachedTrajectoryEnd");

		// Rotate character
		Trapeze.PlayerPositionInSwing.AddLocalRotation(FRotator(0.f, 180.f, 0.f));

		// Add dispenser actor to keep-in-view fullscreen camera
		FHazeFocusTarget KeepInViewFocusTarget;
		KeepInViewFocusTarget.Actor = Trapeze.KeepInViewActor;
		KeepInViewFocusTarget.Type = EHazeFocusTargetType::Object;
		Trapeze.TrapezeCameraActor.AddTarget(KeepInViewFocusTarget);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Tick throw
		if(bThrowInProgress)
		{
			ThrowTimer += DeltaTime;
			if(ThrowTimer >= ThrowMark && !TrapezeComponent.bJustThrewMarble)
			{
				ThrowMarble();
			}
		}
		// Call net function when player presses throw trigger
		else if(WasActionStarted(ActionNames::WeaponFire))
		{
			StartThrowAnimation(TrapezeComponent.DispenserIsWithinThrowRange());
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TrapezeComponent.IsSwinging())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bMarbleReachedTrajectoryEnd)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(TrapezeTags::MarbleThrow, this);

		// Rotate character
		Trapeze.PlayerPositionInSwing.AddLocalRotation(FRotator(0.f, 180.f, 0.f));

		// Clear camera crap
		Trapeze.TrapezeCameraActor.RemoveTarget(Trapeze.KeepInViewActor);

		// Cleanup!
		MarbleReachedTrajectoryEnd.Clear();
		TrapezeComponent.bJustThrewMarble = false;
		ThrowTimer = 0.f;
		bMarbleReachedTrajectoryEnd = false;
		bAssistedThrow = false;
		bThrowInProgress = false;
	}

	UFUNCTION(NetFunction)
	void StartThrowAnimation(bool bNetAssistedThrow)
	{
		Trapeze.AnimationDataComponent.bIsThrowing = true;

		bAssistedThrow = bNetAssistedThrow;
		bThrowInProgress = true;
		ThrowTimer = 0.f;
	}

	void ThrowMarble()
	{
		// Communicate throw to pickup component
		UPlayerPickupComponent PickupComponent = UPlayerPickupComponent::Get(PlayerOwner);
		PickupComponent.ThrowRelease();

		// Add them throw trace ignores
		TArray<AActor> ThrowIgnores;
		ThrowIgnores.Add(Trapeze);
		ThrowIgnores.Add(Trapeze.OtherTrapeze);

		// Get throw vector; throw is assisted if player is close enough to target
		FVector ThrowVector;
		if(bAssistedThrow)
		{
			float ThrowHeight = TrapezeComponent.GetDistanceToTargetDispenser() * 0.2f;
			ThrowVector = CalculateVelocityForPathWithHeight(Marble.ActorLocation, Trapeze.TargetDispenserLocation, UHazeMovementComponent::Get(PlayerOwner).GravityMagnitude, ThrowHeight);
		}
		else
		{
			// Get throw vector and raise pitch
			ThrowVector = -Trapeze.ActorForwardVector.RotateAngleAxis(50.f, PlayerOwner.ActorRightVector) * 1300.f;

			// Add trapeze momentum
			if(-Trapeze.ActorForwardVector.DotProduct(Trapeze.SwingMesh.GetPhysicsLinearVelocity().GetSafeNormal()) > 0.f)
				ThrowVector += Trapeze.SwingMesh.GetPhysicsLinearVelocity().ConstrainToDirection(-Trapeze.ActorForwardVector);
		}

		// Throw that shit!
		UPickupThrowComponent ThrowComponent = UPickupThrowComponent::GetOrCreate(PlayerOwner);
		ThrowComponent.Throw_Legacy(Marble, Marble.ActorLocation, ThrowVector * Marble.MeshMass, Marble.MeshMass, 1.8f, MarbleReachedTrajectoryEnd, Marble.HasControl(), true, ThrowIgnores);

		// What's done is done
		TrapezeComponent.bJustThrewMarble = true;
		Marble.OnMarbleThrownEvent.Broadcast(PlayerOwner, bAssistedThrow);

		// Throw animation is done playing
		Trapeze.AnimationDataComponent.bIsThrowing = false;
	}

	// Should only be called when failing
	UFUNCTION(NotBlueprintCallable)
	void OnMarbleReachedTrajectoryEnd(AActor ProjectileActor, FVector LastTracedVelocity, FHitResult HitResult, bool bIsControlThrow)
	{
		Marble.LandMarbleAfterThrow();
		bMarbleReachedTrajectoryEnd = true;
	}
}