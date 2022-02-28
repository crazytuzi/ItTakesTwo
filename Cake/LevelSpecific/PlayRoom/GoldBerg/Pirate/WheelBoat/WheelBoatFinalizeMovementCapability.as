import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatMovementData;


class UWheelBoatFinalizeMovementCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatMovement");

    default TickGroup = ECapabilityTickGroups::LastMovement;

	AWheelBoatActor WheelBoat;
	UHazeBaseMovementComponent MoveComp;
	UHazeCrumbComponent LeftCrumbComponent;
	UHazeCrumbComponent RightCrumbComponent;

	FVector ImpactDirection;
	FWheelBoatImpactData ActiveImpactData;
	float ImpactTriggerGameTime;
	float ImpactTriggerRoundTripSeconds;
	float ImpactGameTime;

	// How much damage to take
	float DamageAmount = 1.f;

	// How long until we can take damage again
	float DamageAgainCooldown = 2.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		WheelBoat = Cast<AWheelBoatActor>(Owner);
		MoveComp = UHazeBaseMovementComponent::Get(WheelBoat);
		LeftCrumbComponent = UHazeCrumbComponent::Get(WheelBoat.LeftWheelSubActor);
		RightCrumbComponent = UHazeCrumbComponent::Get(WheelBoat.RightWheelSubActor);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.UseBossFightMovement())
			return EHazeNetworkActivation::DontActivate;

    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			 return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.PlayerInLeftWheel == nullptr || WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.UseBossFightMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WheelBoat.RotationBase.SetRelativeRotation(FRotator::ZeroRotator);
		
		WheelBoat.LeftWheelSubActor.CleanupCurrentMovementTrail();
		WheelBoat.RightWheelSubActor.CleanupCurrentMovementTrail();

		WheelBoat.LeftWheelSplashEffect.Activate();
		WheelBoat.RightWheelSplashEffect.Activate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WheelBoat.LeftWheelSplashEffect.Deactivate();
		WheelBoat.RightWheelSplashEffect.Deactivate();
	}
	
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FWheelBoatMovementData& LeftMovementData = WheelBoat.LeftWheelSubActor.MovementData;
		FWheelBoatMovementData& RightMovementData = WheelBoat.RightWheelSubActor.MovementData;

		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"WheelBoatMovement");
		const float BonusAlpha = FMath::Max((LeftMovementData.WheelMovementVelocity + RightMovementData.WheelMovementVelocity) - 0.5f, 0.f) * 2; 

		FRotator DeltaRotation;
		DeltaRotation.Yaw += LeftMovementData.RequestedDeltaRotationYaw;
		DeltaRotation.Yaw -= RightMovementData.RequestedDeltaRotationYaw;
		DeltaRotation *= 1.f + (WheelBoat.TurnSpeedMultiplier * BonusAlpha);

		FRotator FinalRotation = WheelBoat.ActorRotation;
		FinalRotation += DeltaRotation;

		FVector FinalDelta;
		FinalDelta += LeftMovementData.RequestedDeltaMovement;
		FinalDelta += RightMovementData.RequestedDeltaMovement;
		FinalDelta *= 1.f + (WheelBoat.TurnSpeedMultiplier * BonusAlpha);

		if(WheelBoat.IsInStream())
		{
			ModifyFromStreamData(DeltaTime, FinalDelta, FinalRotation);
		}

		if(WheelBoat.bReactingToImpact)
		{
			ModifyFromImpactData(DeltaTime, FinalDelta, FinalRotation);
		}

		if(WheelBoat.IsAvoidingPoint())
		{
			ModifyFromAvoidPoint(DeltaTime, FinalDelta, FinalRotation);
		}

		// Apply the othersides wanted location
		if (Network::IsNetworked())
		{
			ModifyFromCrumbData(LeftCrumbComponent, DeltaTime, FinalDelta, FinalRotation);
			ModifyFromCrumbData(RightCrumbComponent, DeltaTime, FinalDelta, FinalRotation);
		}
		
		MoveComp.SetTargetFacingRotation(FinalRotation);
		Movement.ApplyTargetRotationDelta();

		// Always align the boat to the Z plain
		Movement.ApplyDeltaWithCustomVelocity(FVector(0.f, 0.f, WheelBoat.BoatZLocation - WheelBoat.ActorLocation.Z), FVector::ZeroVector);

		Movement.ApplyDelta(FinalDelta);
		
		FVector LastActorLocation = WheelBoat.ActorLocation;
		MoveComp.Move(Movement);

		FWheelBoatImpactData ImpactData;
		if(WheelBoat.IsInStream())
			ImpactData = WheelBoat.BoatSettings.StreamImpact;
		else
			ImpactData = WheelBoat.BoatSettings.RegularImpact;

		CheckImpact(ImpactData, WheelBoat.ActorLocation - LastActorLocation);
		CheckImpactOutsideImpact();

		LeftCrumbComponent.LeaveMovementCrumb();
		RightCrumbComponent.LeaveMovementCrumb();

		WheelBoat.FinalizeMovement(DeltaTime);
    }

	void ModifyFromStreamData(float DeltaTime, FVector& OutFinalDelta, FRotator& OutFinalRotation)
	{
		// The stream will always try to rotate us in the stream direction
		const FVector CurrentStreamDirection = WheelBoat.StreamComponent.StreamDirection;
		FRotator SteamRotation = CurrentStreamDirection.Rotation();

		const FVector DeltaToCenter = WheelBoat.StreamComponent.PositionClosestToBoat - WheelBoat.ActorLocation;
		const FVector DirToStreamCenter = DeltaToCenter.GetSafeNormal();
		const float DistToCenter = DeltaToCenter.Size();

		float MoveToCenterAlpha = 1;
		const float ValidDistance = WheelBoat.StreamComponent.LockedStream.AllowedDistanceFromSpline;
		if(ValidDistance > 0)
			MoveToCenterAlpha = FMath::Min(DistToCenter / ValidDistance, 1.f);

		if(MoveToCenterAlpha > 0.5f)
		{
			MoveToCenterAlpha -= 0.5f;
			MoveToCenterAlpha += MoveToCenterAlpha;
			FVector MoveToCenterDelta = FMath::Lerp(FVector::ZeroVector, FMath::Min(DirToStreamCenter * DeltaTime * FMath::Lerp(50.f, 250.f, MoveToCenterAlpha), DeltaToCenter), MoveToCenterAlpha);
			MoveToCenterDelta.Z = 0;
			OutFinalDelta += MoveToCenterDelta;
		}

		// We turn faster when we try to turn toward the stream
		const float AlignedWithStreamAlpha = 1.f - FMath::Max(CurrentStreamDirection.DotProduct(WheelBoat.ActorForwardVector), 0.f);
		const float LerpSpeed = FMath::Lerp(WheelBoat.BoatSettings.StreamForceRotationSpeed.Min, WheelBoat.BoatSettings.StreamForceRotationSpeed.Max, AlignedWithStreamAlpha);
		OutFinalRotation = FMath::RInterpTo(OutFinalRotation, SteamRotation, DeltaTime, LerpSpeed);
	}

	void ModifyFromAvoidPoint(float DeltaTime, FVector& OutFinalDelta, FRotator& OutFinalRotation)
	{
		const FWheelBoatAvoidPositionData& AvoidData = WheelBoat.AvoidPoint;
		FVector ForceAway = AvoidData.GetForce(WheelBoat.GetActorLocation());
		ForceAway *= DeltaTime;
		OutFinalDelta += ForceAway;
	}

	void ModifyFromCrumbData(UHazeCrumbComponent CrumbComp, float DeltaTime, FVector& OutFinalDelta, FRotator& OutFinalRotation)
	{
		float SyncAlpha = 1;

		const float GameSeconds = Time::GetGameTimeSeconds();
		
		if(WheelBoat.ImpactCount > 0 )
		{
			const float IgnoreTime = ImpactTriggerRoundTripSeconds + 0.1f;
			const float ZeroMaxTime = ImpactTriggerGameTime + ActiveImpactData.ApplyTime + IgnoreTime;
			if(ZeroMaxTime > GameSeconds)
			{
				SyncAlpha = 0;
			}
			else
			{
				const float LerpingTime = 0.5f;
				const float LerpingMaxTime = ImpactTriggerGameTime + ActiveImpactData.ApplyTime + ImpactTriggerRoundTripSeconds + LerpingTime + IgnoreTime;
				const float CurrentTime = FMath::Max(LerpingMaxTime - GameSeconds, 0.f);
				SyncAlpha = 1.f - FMath::Min(CurrentTime / LerpingTime, 1.f);
			}
		}

		if(!CrumbComp.HasControl())
		{	
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			if(SyncAlpha > 0)
			{
				// Sync location
				{
					FVector BoatLocation = WheelBoat.ActorLocation;
					const float Distance = ConsumedParams.Location.Distance(BoatLocation);
					float SyncAmount = FMath::Min(FMath::Max(Distance - 100.f, 0.f) / 1000.f, 1.f);
					float SyncLocationAlpha = FMath::Lerp(0.f, 0.5f, SyncAmount) * SyncAlpha;

					if(SyncLocationAlpha > 0)
					{
						const FVector MedianLocation = FMath::Lerp(WheelBoat.ActorLocation, ConsumedParams.Location, SyncLocationAlpha);
						const FVector FinalLocation = FMath::VInterpTo(WheelBoat.ActorLocation, MedianLocation, DeltaTime, 0.5f);
						OutFinalDelta += (FinalLocation - WheelBoat.ActorLocation);
					}

					// Fix up the side offset
					FVector SideDelta = ConsumedParams.Location - BoatLocation;
					float DotAmount = SideDelta.DotProduct(WheelBoat.ActorRotation.RightVector);
					if(FMath::Abs(DotAmount) > 10.f)
					{
						const FVector FinalLocation = FMath::VInterpTo(WheelBoat.ActorLocation, WheelBoat.ActorLocation + SideDelta, DeltaTime, 0.5f);
						OutFinalDelta += (FinalLocation - WheelBoat.ActorLocation);
					}	
				}
	
				// Sync Rotation
				{
					FRotator BoatRotation = WheelBoat.ActorRotation;
					FRotator CrumbRotation = ConsumedParams.Rotation;
					
					if(WheelBoat.IsInStream())
					{
						BoatRotation = WheelBoat.RotationBase.WorldRotation;
						CrumbRotation = ConsumedParams.CustomCrumbRotator;
					}

					float AngleDiff = Math::GetAngle(BoatRotation.ForwardVector, CrumbRotation.ForwardVector);
					float SyncAmount = FMath::Min(FMath::Max(AngleDiff - 1.f, 0.f) / 15.f, 1.f);
					float SyncRotationAlpha = FMath::Lerp(0.f, 0.5f, SyncAmount) * SyncAlpha;

					if(SyncRotationAlpha > 0)
					{
						const FRotator MedianRotation = FMath::LerpShortestPath(BoatRotation, CrumbRotation, SyncRotationAlpha);
						const FRotator FinalRotation = FMath::RInterpTo(BoatRotation, MedianRotation, DeltaTime, 0.25f);
						OutFinalRotation.Yaw += (FinalRotation - BoatRotation).Yaw;
					}
				}
			}
		}
	}

	void ModifyFromImpactData(float DeltaTime, FVector& OutFinalDelta, FRotator& OutFinalRotation)
	{
		const float ImpactTimeLeft = FMath::Max(ActiveImpactData.ApplyTime - (Time::GetGameTimeSeconds() - ImpactTriggerGameTime), 0.f);
		const float ImpactDeltaTime = FMath::Min(DeltaTime, ImpactTimeLeft);
		const float ImpactForce = ActiveImpactData.ImpactForce * ImpactDeltaTime;
		const float ImpactPercentage = 1 - ImpactTimeLeft / ActiveImpactData.ApplyTime;
		if(ImpactTimeLeft <= SMALL_NUMBER)
		 	WheelBoat.bReactingToImpact = false;

		float InputPercentage = 0;
		if(ImpactPercentage >= ActiveImpactData.LockedInputPercentage)
		{
			InputPercentage = ImpactPercentage - ActiveImpactData.LockedInputPercentage / (1.f - ActiveImpactData.LockedInputPercentage);
			InputPercentage = FMath::Lerp(ActiveImpactData.InputAmountPercentage.Min, ActiveImpactData.InputAmountPercentage.Max, InputPercentage);
		}

		const float LerpAlpha = FMath::Clamp(InputPercentage, 0.f, 1.f);
		OutFinalDelta = FMath::Lerp(ImpactDirection * ImpactForce, OutFinalDelta, LerpAlpha);
		OutFinalRotation = FMath::LerpShortestPath(WheelBoat.ActorRotation, OutFinalRotation, FMath::EaseOut(0.f, 1.f, LerpAlpha, 2.f));
	}

	void CheckImpact(FWheelBoatImpactData ImpactData, FVector DeltaMove)
	{
		if(DeltaMove.SizeSquared() < 1.f)
			return;

		if(ImpactData.ApplyTime <= 0)
			return;

		if(ImpactData.ImpactForce <= 0)
			return;

		if(ImpactData.SpeedValidation.Min > WheelBoat.MovementComponent.Velocity.Size())
			return;

		FHazeTraceParams FrameTrace;
		FrameTrace.InitWithPrimitiveComponent(WheelBoat.CapsuleComponent);
		FrameTrace.MarkToTraceWithOriginOffset();
		FrameTrace.IgnoreActor(WheelBoat);

		FrameTrace.From = WheelBoat.GetActorLocation();
		FrameTrace.To = FrameTrace.From + DeltaMove;
		//FrameTrace.DebugDrawTime = 0;

		FHazeHitResult CollisionTrace;
		bool bResult = FrameTrace.Trace(CollisionTrace);

		if(!CollisionTrace.bBlockingHit)
			return;

		if(CollisionTrace.bStartPenetrating)
			return;
			
		FVector ImpactNormal = FVector::ZeroVector;
		float Multiplier = 1;
		ExtractImpactNormalAndImpactMultiplier(CollisionTrace, ImpactData, ImpactNormal, Multiplier);
		NetTriggerImpact(WheelBoat.ImpactCount + 1, ImpactData, ImpactNormal, Multiplier);
	}

	void CheckImpactOutsideImpact()
	{
		if(WheelBoat.PendingImpactWithActor == nullptr)
			return;

		FVector ImpactNormal = (WheelBoat.GetActorLocation() - WheelBoat.PendingImpactWithActor.GetActorLocation()).GetSafeNormal();
		NetTriggerImpact(WheelBoat.ImpactCount + 1, WheelBoat.BoatSettings.RegularImpact, ImpactNormal, 2.f);
	}

	void ExtractImpactNormalAndImpactMultiplier(FHazeHitResult Hit, FWheelBoatImpactData ImpactData, FVector& OutImpactNormal, float& OutMultiplier)
	{
		FVector HitLocation = Hit.FHitResult.Location;
	 	HitLocation.Z = WheelBoat.BoatZLocation;
		FVector DirToImpact = (HitLocation - WheelBoat.GetActorLocation()).GetSafeNormal();
		FVector ImpactNormal = Hit.Normal;
		
		float BoatVelocityAmount = FMath::Min(WheelBoat.MovementComponent.Velocity.Size(), ImpactData.SpeedValidation.Max);
		float Multiplier = FMath::Max(DirToImpact.DotProduct(WheelBoat.ActorForwardVector), 0.f);
		float SpeedMultiplier = BoatVelocityAmount / ImpactData.SpeedValidation.Max;

		// In the stream, be bounce in the stream direction
		if(WheelBoat.IsInStream())
		{	
			const float UseNormalAlpha = 1.f - Math::GetLinearDotProduct(ImpactNormal, WheelBoat.StreamComponent.StreamDirection);
			const FVector DirToBestPoint = (WheelBoat.StreamComponent.PositionClosestToBoat - WheelBoat.ActorLocation).GetSafeNormal();

			Multiplier *= FMath::Lerp(1.5f, 0.5f, UseNormalAlpha);
			ImpactNormal = FMath::Lerp(DirToBestPoint, ImpactNormal, UseNormalAlpha).GetSafeNormal();
		}

		OutImpactNormal = ImpactNormal;
		OutMultiplier = FMath::Max(Multiplier * SpeedMultiplier, 0.2f);
	}

	UFUNCTION(NetFunction)
	void NetTriggerImpact(int ImpactNumber, FWheelBoatImpactData ImpactType, FVector WantedImpactDirection, float Multiplier)
	{
		WheelBoat.PendingImpactWithActor = nullptr;

		// Invalid impact number
		if(ImpactNumber < WheelBoat.ImpactCount)
			return;

		// Only the server can control the same impact number
		if(ImpactNumber == WheelBoat.ImpactCount && !HasControl())
			return;

		WheelBoat.ImpactCount = ImpactNumber;
		WheelBoat.bReactingToImpact = true;
		
		ImpactDirection = WantedImpactDirection;
		ActiveImpactData = ImpactType;
		ActiveImpactData.ImpactForce *= Multiplier;
		ActiveImpactData.ApplyTime *= Multiplier;

		ImpactTriggerGameTime = Time::GetGameTimeSeconds();
		ImpactTriggerRoundTripSeconds = Network::GetPingRoundtripSeconds();
		FVector NewBoatVelocity = ImpactDirection * ActiveImpactData.ImpactForce;
		if(!NewBoatVelocity.IsNearlyZero())
		{
			WheelBoat.LeftWheelSubActor.MovementData.BoatVelocity = NewBoatVelocity;
			WheelBoat.RightWheelSubActor.MovementData.BoatVelocity = NewBoatVelocity;
		}

		WheelBoat.TriggerImpact(FMath::Max(0.15f, Multiplier));

		float CurrentGameTime = Time::GetGameTimeSeconds();
		if(CurrentGameTime >= ImpactGameTime && WheelBoat.IsInStream())
		{
			WheelBoat.BoatWasHit(DamageAmount, EWheelBoatHitType::CollisionImpact);
			ImpactGameTime = CurrentGameTime + DamageAgainCooldown;
		}

		//Print("ImpactForce: " + ActiveImpactData.ImpactForce, 1.f);
		//Print("Velo: " + WheelBoat.MovementComponent.Velocity.Size(), 1.f);

		float AudioImpactVelo = HazeAudio::NormalizeRTPC01(WheelBoat.MovementComponent.Velocity.Size(), 250.f, 500.f);
		float AudioImpactForce = HazeAudio::NormalizeRTPC01(ActiveImpactData.ImpactForce, 250.f, 500.f);

		//Print("AudioImpactForce: " + AudioImpactForce * AudioImpactVelo, 1.f);

		WheelBoat.AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_CollisionForce", AudioImpactForce * AudioImpactVelo);
	}
}