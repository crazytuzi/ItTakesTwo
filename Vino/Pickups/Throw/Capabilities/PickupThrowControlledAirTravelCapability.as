import Vino.Pickups.PickupActor;

class UPickupThrowControlledAirTravelCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupThrowControlledAirTravelCapability);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	APickupActor PickupOwner;

	FRotator AngularSpeed;

	FQuat InitialRotation;
	FHazeAcceleratedQuat AcceleratedPickupRootRotation;

	const float StepModifier = 0.8f;

	float TimeToCollision;

	bool bRestoringLocalMeshRotation;
	bool bHasSnappedInitialRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupOwner = Cast<APickupActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PickupOwner.ThrowParams == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(PickupOwner.ThrowType != EPickupThrowType::Controlled)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PickupOwner.MovementComponent.Activate();
		PickupOwner.CollisionShape.Activate();

		if(HasControl())
			PickupOwner.MovementComponent.SetVelocity(PickupOwner.ThrowParams.ThrowVelocity);

		PickupOwner.CustomTimeDilation = StepModifier;

		if(HasControl())
			TimeToCollision = PickupOwner.ThrowParams.Time;

		// Save original rotation and randomize air angular speed
		AngularSpeed = FRotator(FMath::RandRange(-5.f, -500.f), 0.f, FMath::RandRange(-300.f, 300.f));

		// Transform and save world actor rotation into relative pickup root rotation
		InitialRotation = PickupOwner.PickupRoot.RelativeTransform.TransformRotation(PickupOwner.ActorRotation.Quaternion()) * PickupOwner.OriginalPickupRootRelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = PickupOwner.MovementComponent.MakeFrameMovement(PickupTags::PickupThrowControlledAirTravelCapability);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);

		if(HasControl())
		{
			// Apply velocity and move
			FVector Velocity = PickupOwner.MovementComponent.Velocity + PickupOwner.ThrowParams.Gravity * DeltaTime;
			MoveData.ApplyVelocity(Velocity);
			// MoveData.SetRotation(Velocity.ToOrientationQuat());

			// Move
			PickupOwner.MovementComponent.Move(MoveData);

			// Check for hits this frame
			if(PickupOwner.MovementComponent.HasAnyBlockingHit())
			{
				FHitResult HitResult;
				if(PickupOwner.MovementComponent.IsCollidingWithWall(HitResult))
				{
					// Get reflection vector with restitution as multiplier
					float VelocityDotNormal = 1.f - Math::Saturate((-Velocity).GetSafeNormal().DotProduct(HitResult.ImpactNormal));
					float BounceMultiplier = FMath::Pow(VelocityDotNormal, 2.f);
					BounceMultiplier = FMath::Clamp(BounceMultiplier, 0.05f, 0.5f);

					// Fire collision event
					PickupOwner.ThrowParams.OnPickupThrowCollision.Broadcast(Velocity, HitResult);

					// Bounce and set velocity
					FVector BounceVelocity = Math::GetReflectionVector(Velocity, HitResult.ImpactNormal) * BounceMultiplier;
					PickupOwner.MovementComponent.SetVelocity(BounceVelocity);
				}
				else if(PickupOwner.MovementComponent.DownHit.Actor != nullptr)
				{
					FHitResult GroundHit = PickupOwner.MovementComponent.DownHit;

					if(!bRestoringLocalMeshRotation)
					{
						// Brake horizontal velocity
						FVector HorizontalVelocity = PickupOwner.MovementComponent.Velocity.ConstrainToPlane(PickupOwner.MovementWorldUp);
						PickupOwner.MovementComponent.SetVelocity(PickupOwner.MovementComponent.Velocity - HorizontalVelocity);

						// Start restoring rotation
						AcceleratedPickupRootRotation.SnapTo(PickupOwner.PickupRoot.RelativeRotation.Quaternion());
						bRestoringLocalMeshRotation = true;
					}

					// Lerp that shit back to its original rotation
					// FVector TargetRotationVector = PickupOwner.OriginalActorRotation.Vector() * FVector::UpVector;
					// TargetRotationVector += PickupOwner.ActorRotation.Vector() * (FVector::OneVector - FVector::UpVector);
					// PickupOwner.LerpToRotation(FPickupRotationLerpParams(TargetRotationVector.ToOrientationQuat()));


					// PickupOwner.SetActorLocation(GroundHit.ImpactPoint);
					// if(AcceleratedMeshRotation.Value.Equals(OriginalMeshRotation))
					// 	bRestoringLocalMeshRotation = false;
				}
			}

			TickMeshRotation(DeltaTime);

			// Finally leave movement crumb
			PickupOwner.CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			PickupOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);

			PickupOwner.MovementComponent.Move(MoveData);
		}
	}

	void TickMeshRotation(float DeltaTime)
	{
		// Eman NOTE: Snapping rotation before moving the actor for at least one frame doesn't seem to work. WHY?! ='(
		if(!bHasSnappedInitialRotation)
		{
			AcceleratedPickupRootRotation.SnapTo(PickupOwner.OriginalPickupRootRelativeRotation * PickupOwner.ActorRotation.Quaternion().Inverse() * InitialRotation);
			bHasSnappedInitialRotation = true;
		}

		AcceleratedPickupRootRotation.AccelerateTo(PickupOwner.OriginalPickupRootRelativeRotation, TimeToCollision * 0.8f, DeltaTime);
		PickupOwner.PickupRoot.SetRelativeRotation(AcceleratedPickupRootRotation.Value);

		// Eman TODO: Do air rotation stuff maybe?
		// if(bRestoringLocalMeshRotation)
		// 		PickupOwner.PickupRoot.SetRelativeRotation(AcceleratedPickupRootRotation.AccelerateTo(PickupOwner.OriginalPickupRootRelativeRotation, 0.2f, DeltaTime));
		// else
			// PickupOwner.PickupRoot.AddLocalRotation(AngularSpeed * DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PickupOwner.MovementComponent.DownHit.Actor != nullptr && PickupOwner.MovementComponent.DownHit.Component.HasTag(n"Walkable") /*&& PickupOwner.PickupRoot.RelativeRotation.Equals(PickupOwner.OriginalPickupRootRelativeRotation.Rotator(), 0.01f)*/)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(IsActioning(PickupTags::AbortPickupFlight))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Attach to floor actor if it contains a dynamic mesh and restore original collision profile
		// PickupFloorAttacherCapability will listen to this event
		PickupOwner.OnStoppedMovingAfterThrowEvent.Broadcast();

		// GC will pwn this guy
		PickupOwner.ThrowParams = nullptr;

		// Restor dilation
		PickupOwner.CustomTimeDilation = 1.f;

		// Gotta restore mesh rotation on preTick
		AcceleratedPickupRootRotation.SnapTo(PickupOwner.OriginalPickupRootRelativeRotation);
		bRestoringLocalMeshRotation = false;

		// Make sure rotation is reset back to origin
		PickupOwner.PickupRoot.SetRelativeRotation(AcceleratedPickupRootRotation.Value);

		bHasSnappedInitialRotation = false;
		TimeToCollision = 0.f;
	}
}