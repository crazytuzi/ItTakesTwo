import Cake.LevelSpecific.Music.KeyBird.KeyBird;

class UKeyBirdMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"KeyBird");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AKeyBird KeyBird;
	UHazeCrumbComponent CrumbComp;
	USteeringBehaviorComponent Steering;
	UKeyBirdSettings Settings;
	
	FVector CurrentSteeringDirection;

	float CurrentVelocity = 0.0f;
	float CurrentRoll = 0.0f;
	float DistanceAlphaCurrent = 1;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		Steering = USteeringBehaviorComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		Settings = UKeyBirdSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(KeyBird.bStartAttack)
			return EHazeNetworkActivation::DontActivate;

		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkActivation::DontActivate;

		if(!Steering.bEnableSeekBehavior)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentSteeringDirection = Owner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(KeyBird.bStartAttack)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!Steering.bEnableSeekBehavior)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(KeyBird.IsDead())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Owner.CleanupCurrentMovementTrail(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat FacingRotation;
		CalculateFrameMove(FacingRotation, DeltaTime);
		KeyBird.MeshOffset.OffsetRotationWithTime(FacingRotation.Rotator(), 0.05f);
	}

	void CalculateFrameMove(FQuat& NewFacingRotation, float DeltaTime)
	{
		if(HasControl())
		{
			float DistanceAlpha = 1.0f;//(!Steering.Avoidance.bIsInside ? FMath::Min(Steering.Avoidance.DistanceToImpactOriginSq / FMath::Square(Steering.Avoidance.AheadFar), 1.0f) : 1.0f);
			//PrintToScreen("DistanceAlpha " + DistanceAlpha);
			DistanceAlpha = 1.0f + FMath::GetMappedRangeValueClamped(FVector2D(0.0f, 1.0f), FVector2D(3.0f, 0.0f), DistanceAlpha);
			
			float DragMul = FMath::GetMappedRangeValueClamped(FVector2D(-1.0f, 1.0f), FVector2D(1.6f, 1.0f), CurrentSteeringDirection.DotProduct(Steering.DirectionToTarget));
			
			float ExtraImpulse = 0;

			if(Steering.bEnableAvoidanceBehavior && (Steering.Avoidance.bAppliedAvoidance || Steering.Avoidance.bIsInside))
			{
				DistanceAlpha *= 2.5f;
				ExtraImpulse = 300;
			}
			
			DistanceAlphaCurrent = FMath::EaseIn(DistanceAlphaCurrent, DistanceAlpha, DeltaTime, 2.0f);
			const float DistanceMinimumSq = FMath::Square(4500.0f);
			const float DistanceToLocation = Steering.Seek.SeekLocation.DistSquared(Steering.WorldLocation);

			float DistanceMultiplier = 1.0f;
			float TurnRateDistanceMul = 1.0f;

			if(Settings.bSlowdownDistance
			&& DistanceToLocation < FMath::Square(Settings.DistanceSlowdownScale.X))
			{
				DistanceMultiplier = FMath::Max((DistanceToLocation - FMath::Square(Settings.DistanceSlowdownScale.Y)) / FMath::Square(Settings.DistanceSlowdownScale.X), 0.0f);
			}

			float D = FMath::Min(DistanceToLocation / FMath::Square(5000.0f), 1.0f);

			const FVector DirectionToTarget = (Steering.Seek.SeekLocation - Steering.WorldLocation).GetSafeNormal();
			float LookAt = FMath::Max(DirectionToTarget.DotProduct(Steering.ForwardVector), 0.1f);
			//PrintToScreen("D " + D);
			
			float T = FMath::Lerp(1.0f, LookAt, D);
			//PrintToScreen("T " + T);
			LookAt = T;
			
			const float SpeedMul = FMath::EaseIn(Settings.LookAtMovementScale.X, Settings.LookAtMovementScale.Y, LookAt, 2);

			const float TurnSpeedMul = FMath::EaseOut(Settings.LookAtRotationScale.X, Settings.LookAtRotationScale.Y, LookAt, 2.0f);
			
			float TurnSpeed = (Settings.TurnRate * TurnSpeedMul) * DistanceAlpha;
			//PrintToScreen("DistanceMultiplier" + DistanceMultiplier);
			if(!KeyBird.CombatArea.Shape.IsPointOverlapping(Steering.AheadLocation))
			{
				TurnSpeed *= 2.0f;

				if(!KeyBird.CombatArea.CombatAreaShape.IsPointOverlapping(Steering.AheadFarLocation))
				{
					TurnSpeed *= 2.0f;
				}
			}

			
			
			//if(DistanceMultiplier < 1.0f)
			//	DistanceAlpha *= 

			//System::DrawDebugLine(Owner.ActorLocation, Steering.Seek.SeekLocation, FLinearColor::Red);
			//System::DrawDebugSphere(Steering.Seek.SeekLocation, 200.0f, 12, FLinearColor::Green);
			
			CurrentSteeringDirection = FQuat::Slerp(CurrentSteeringDirection.ToOrientationQuat(), Steering.DirectionToTarget.ToOrientationQuat(), TurnSpeed * DeltaTime).Vector();
			//CurrentSteeringDirection = Steering.DirectionToTarget;
			//System::DrawDebugLine(Steering.WorldLocation, Steering.WorldLocation + Steering.ForwardVector * 1500, FLinearColor::DPink, 0, 50);
			float YawTurn = FMath::Clamp(FMath::FindDeltaAngleRadians(CurrentSteeringDirection.X, Steering.DirectionToTarget.X), -1.0f, 1.0f);
			//PrintToScreen("YawTurn " + YawTurn);
			
			CurrentVelocity = Steering.VelocityMagnitude;
			CurrentVelocity *= FMath::Pow(Settings.Drag * DragMul, DeltaTime);
			CurrentVelocity = FMath::Min(CurrentVelocity + (Settings.Acceleration * SpeedMul) * DeltaTime, (Settings.VelocityMaximum + ExtraImpulse) * DistanceMultiplier);
			
			const float RollTurnRate = 80.0f;
			CurrentRoll = FMath::FInterpTo(CurrentRoll, RollTurnRate * YawTurn, DeltaTime, 1.0f);

			KeyBird.MeshBody.RelativeRotation = FRotator(0.0f, 0.0f, CurrentRoll);
			
			Steering.Velocity = KeyBird.CurrentVelocity;
			Steering.VelocityMagnitude = CurrentVelocity;

			Owner.AddActorWorldOffset(CurrentSteeringDirection * CurrentVelocity * DeltaTime);
			KeyBird.ReplicatedLocation.Value = Owner.ActorLocation;
			KeyBird.ReplicatedDirection.Value = CurrentSteeringDirection;
		}
		else
		{
			float YawTurn = FMath::Clamp(FMath::FindDeltaAngleRadians(KeyBird.ReplicatedDirection.Value.X, KeyBird.MeshBody.WorldRotation.Vector().X), -1.0f, 1.0f) * 10.0f;
			//PrintToScreen("YawTurn " + YawTurn);
			const float RollTurnRate = 80.0f;
			CurrentRoll = FMath::FInterpTo(CurrentRoll, RollTurnRate * YawTurn, DeltaTime, 1.0f);
			KeyBird.MeshBody.RelativeRotation = FRotator(0.0f, 0.0f, CurrentRoll);
			CurrentSteeringDirection = KeyBird.ReplicatedDirection.Value;
			Owner.SetActorLocation(KeyBird.ReplicatedLocation.Value);
		}

		NewFacingRotation = KeyBird.bCustomFacingDirection ? KeyBird.TargetFacingDirection.ToOrientationQuat() : CurrentSteeringDirection.ToOrientationQuat();
	}
}
