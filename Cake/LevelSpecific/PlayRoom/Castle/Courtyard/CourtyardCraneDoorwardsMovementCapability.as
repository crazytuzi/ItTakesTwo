import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardCraneActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneWreckingBall;

class UCourtyardCraneDoorwardsMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 40;

	ACourtyardCraneAttachedActor SwingActor;
	ACourtyardCraneWreckingBall WreckingBall;
	ACastleCourtyardCraneActor CraneActor;
	UHazeCrumbComponent CrumbComp;

	float SwingRadius = 2000.f;
	const float MaxGravity = 8.f;
	const float MinGravity = 3.2f;

	FVector TargetPosition;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwingActor = Cast<ACourtyardCraneAttachedActor>(Owner);
		WreckingBall = Cast<ACourtyardCraneWreckingBall>(SwingActor);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WreckingBall == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(n"Attached"))
			return EHazeNetworkActivation::DontActivate;

		if (WreckingBall.LeftPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (WreckingBall.RightPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"Attached"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (WreckingBall.LeftPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (WreckingBall.RightPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Owner.BlockCapabilities(n"SwingHorizontal", this);

		CraneActor = Cast<ACastleCourtyardCraneActor>(GetAttributeObject(n"CraneActor"));

		SwingRadius = CraneActor.AcceleratedConstraintLength.Value;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SwingHorizontal", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			SwingRadius = CraneActor.AcceleratedConstraintLength.Value;
			//System::DrawDebugSphere(ConstraintPoint.WorldLocation, SwingRadius, 20.f, FLinearColor::White, 0.f, 2.f);

			FVector Direction = -GetBallToConstraint();
			Direction.Normalize();

			FVector GravityForce = Direction.CrossProduct(-FVector::UpVector * Gravity);
			SwingActor.AngularVelocity += GravityForce * DeltaTime;

			FVector Impulse;
			ConsumeAttribute(n"ExplosionImpulse", Impulse);
			FVector ImpulseAngularVelocity = Direction.CrossProduct(Impulse);
			SwingActor.AngularVelocity += ImpulseAngularVelocity;
			
			float InteractingPlayers = 0.f;
			if (WreckingBall != nullptr)
			{
				if (WreckingBall.LeftPlayer != nullptr)
					InteractingPlayers += 1.f;
				if (WreckingBall.RightPlayer != nullptr)
					InteractingPlayers += 1.f;
			}
			const float InteractingPlayerScale = InteractingPlayers / 2.f;

			// Player acceleration
			if (WreckingBall != nullptr)
			{
				// Get average input and pow it to make a single player very weak solo
				// Allow negatives so you can get the swing started
				float InputScale = (WreckingBall.MayAccelerationStrengthSyncFloat.Value + WreckingBall.CodyAccelerationStrengthSyncFloat.Value);
				if (WreckingBall.bCutsceneStarted)
					InputScale = 0.f;
				else
				{
					InputScale /= 2.f;
					InputScale = FMath::Pow(FMath::Abs(InputScale), 1.4f) * FMath::Sign(InputScale);
				}

				// Pick a default direction if you aren't moving
				FVector PlayerAccelerationDirection = -SwingActor.ActorRightVector;

				// If you are moving, input should be scaled in the direction of travel, blocking incorrect input (negative numbers)
				bool bIsMoving = !FMath::IsNearlyZero(SwingActor.AngularVelocity.DotProduct(SwingActor.ActorRightVector), 0.01f);
				if (bIsMoving)
				{
					PlayerAccelerationDirection = SwingActor.AngularVelocity.ConstrainToDirection(SwingActor.ActorRightVector).GetSafeNormal();
					InputScale = FMath::Max(InputScale, 0.f);
				}

				FVector PlayerAcceleration = PlayerAccelerationDirection * InputScale * 0.25f * DeltaTime;
				SwingActor.AngularVelocity += PlayerAcceleration;
			}

			// Drag
			{
				const float MinForwardDrag = 0.225f;
				const float MaxForwardDrag = 1.5f;
				const float MinRemainderDrag = 0.5f;
				const float MaxRemainderDrag = 1.5f;
				
				const float ForwardDrag = FMath::Lerp(MaxForwardDrag, MinForwardDrag, InteractingPlayerScale);
				const float RemainderDrag = FMath::Lerp(MinRemainderDrag, MaxRemainderDrag, InteractingPlayerScale);				

				//AngularVelocity -= AngularVelocity.GetSafeNormal() * AngularVelocity.SizeSquared() * DeltaTime;
				FVector ForwardAngularVelocity = CraneActor.ConstraintPoint.RightVector * CraneActor.ConstraintPoint.RightVector.DotProduct(SwingActor.AngularVelocity);
				FVector RemainingAngularVelocity = SwingActor.AngularVelocity - ForwardAngularVelocity;
				ForwardAngularVelocity -= ForwardAngularVelocity * ForwardDrag * DeltaTime;
				RemainingAngularVelocity -= RemainingAngularVelocity * RemainderDrag * DeltaTime;
				SwingActor.AngularVelocity = ForwardAngularVelocity + RemainingAngularVelocity;
			}

			FVector VelAxis;
			float VelMagnitude = 0.f;
			SwingActor.AngularVelocity.ToDirectionAndLength(VelAxis, VelMagnitude);

			if (!FMath::IsNearlyZero(VelMagnitude))
			{
				FQuat DeltaQuat = FQuat(VelAxis, VelMagnitude * DeltaTime);
				Direction = DeltaQuat * Direction;
				Owner.ActorRotation = Math::MakeRotFromZX(-Direction, -CraneActor.ConstraintPoint.ForwardVector);
				Owner.ActorLocation = CraneActor.ConstraintPoint.WorldLocation + Direction * SwingRadius;
			}

			// Calculate a percentage for audio using an arbitrary maximum
			const float AudioCraneSpeedMaximum = 1.8f;
			const float AudioCraneSpeedPercentage = FMath::Clamp(SwingActor.AngularVelocity.Size() / AudioCraneSpeedMaximum, 0.f, 1.f);
			CraneActor.CraneTopHazeAkComp.SetRTPCValue("Rtpc_Castle_Courtyard_Interactable_CraneSpeed", AudioCraneSpeedPercentage);

			CrumbComp.SetCustomCrumbVector(SwingActor.AngularVelocity);

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FVector PreviousDirection = GetBallToConstraint().GetSafeNormal();
			Owner.ActorLocation = ConsumedParams.Location;
			FVector NewDirection = GetBallToConstraint().GetSafeNormal();

			FVector Axis = PreviousDirection.CrossProduct(NewDirection).GetSafeNormal();
			float DeltaAngle = Math::DotToRadians(PreviousDirection.DotProduct(NewDirection));

			SwingActor.AngularVelocity = Axis * (DeltaAngle / DeltaTime);

			// Calculate a percentage for audio using an arbitrary maximum
			const float AudioCraneSpeedMaximum = 1.8f;
			const float AudioCraneSpeedPercentage = FMath::Clamp(SwingActor.AngularVelocity.Size() / AudioCraneSpeedMaximum, 0.f, 1.f);
			CraneActor.CraneTopHazeAkComp.SetRTPCValue("Rtpc_Castle_Courtyard_Interactable_CraneSpeed", AudioCraneSpeedPercentage);
			
			Owner.ActorRotation = Math::MakeRotFromZX(NewDirection, -CraneActor.ConstraintPoint.ForwardVector);
		}		
	}

	FVector GetBallToConstraint() property
	{
		return CraneActor.ConstraintPoint.WorldLocation - SwingActor.ActorLocation;
	}

	float GetGravity() property
	{
		float RadiusPercentage = (CraneActor.AcceleratedConstraintLength.Value - CraneActor.ConstraintSettings.MinimumLength);
		RadiusPercentage /=  CraneActor.ConstraintSettings.MaximumLength - CraneActor.ConstraintSettings.MinimumLength;
		RadiusPercentage = FMath::Clamp(RadiusPercentage, 0.f, 1.f);

		return FMath::Lerp(MaxGravity, MinGravity, RadiusPercentage);
	}
}