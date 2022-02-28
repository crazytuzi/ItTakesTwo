import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourPrepareLungeCapability : UFishBehaviourCapability
{
    default State = EFishState::Combat;
	float LungeTime = BIG_NUMBER;
	float GapeTime = 0.f;
	float OpenwideDuration = 2.f;
	float InViewTime = 0.f;
	AHazePlayerCharacter PlayerTarget;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// Time we start lunge at. 
		LungeTime = Time::GetGameTimeSeconds() + Settings.PrepareLungeDuration;

		// The time to open maw wide, signalling an imminent lunge
		GapeTime = LungeTime - OpenwideDuration;

		InViewTime = System::GetGameTimeInSeconds();

		EffectsComp.SetEffectsMode(EFishEffectsMode::Attack);
		AnimComp.SetGapingPercentage(30.f);
		AnimComp.SetAgitated(true);

		PlayerTarget = Cast<AHazePlayerCharacter>(BehaviourComponent.GetTarget());
		if (PlayerTarget != nullptr)
		{
			FHazePointOfInterest POI;
			POI.FocusTarget.Actor = Owner;
			POI.Blend.BlendTime = 1.f;
			POI.Duration = 1.f;
			PlayerTarget.ApplyPointOfInterest(POI, this);
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		if (PlayerTarget != nullptr)
			PlayerTarget.ClearPointOfInterestByInstigator(this);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		float CurTime = Time::GetGameTimeSeconds();
		AHazeActor Target = BehaviourComponent.GetTarget();
        if (!BehaviourComponent.CanHuntTarget(Target))
        {
            // Lost target
            BehaviourComponent.State = EFishState::Recover; 
            return;
        }

		if (Settings.PrepareLungeKeepTargetInViewTime > 0.f)
		{
			if (InView(Target))
				InViewTime = CurTime;
			if ((BehaviourComponent.StateDuration > 3.f) && (Time::GetGameTimeSince(InViewTime) > Settings.PrepareLungeKeepTargetInViewTime))
			{
				// Target has managed to swim out of view cone/sphere
				BehaviourComponent.State = EFishState::Recover; 
				return;
			}
		}

		float DistToTarget = Owner.GetDistanceTo(Target);
		float Acc =	Settings.PrepareLungeAcceleration;
		float AccDuration = 0.5f;
		if (CurTime > LungeTime - AccDuration)
		{
			// Start lunge
			AnimComp.Lunge();
			float TimeRemaining = LungeTime - CurTime;
			float AttackAcc = Settings.AttackLungeAcceleration;
			AttackAcc = FMath::GetMappedRangeValueClamped(FVector2D(2000.f, 10000.f), FVector2D(Acc, AttackAcc), DistToTarget);
			Acc = FMath::GetMappedRangeValueClamped(FVector2D(0.f, AccDuration), FVector2D(AttackAcc, Acc), TimeRemaining);
		}

		bool bIsNearMaw = BehaviourComponent.IsInVisionSphere(Target.ActorLocation, 0.f);
		if ((CurTime > LungeTime) || (bIsNearMaw && AnimComp.GetGapingPercentage() > 99.f))
        {
            // Charge!
            BehaviourComponent.State = EFishState::Attack;
            return;
        }

		if ((CurTime > GapeTime) || bIsNearMaw)
		{
			float GapeDuration = LungeTime - CurTime;
			if (bIsNearMaw && (GapeDuration > 1.f))
				GapeDuration = 1.f;
			AnimComp.SetGapingPercentage(100.f, GapeDuration);
		}

		// Calculate turn duration based on fraction of lunge time and distance to target
		float TurnDuration = Settings.PrepareLungeTurnDuration;
		if (BehaviourComponent.PrepareLungeTurnSpeedCurve != nullptr)
		{
			float TimeFraction = 1.f - ((LungeTime - CurTime) / Settings.PrepareLungeDuration);
			TurnDuration /= FMath::Max(0.01f, BehaviourComponent.PrepareLungeTurnSpeedCurve.GetFloatValue(TimeFraction));
		}
		float DistFactor = FMath::GetMappedRangeValueClamped(FVector2D(5000.f, 15000.f), FVector2D(1.f, 5.f), DistToTarget);
		TurnDuration *= DistFactor;

        // Keep moving towards target
        BehaviourComponent.MoveTo(Target.ActorLocation, Acc, TurnDuration);
    }

	bool InView(AHazeActor Target)
	{
		if (BehaviourComponent.IsInVisionSphere(Target.ActorLocation, 2000.f))
			return true;
		if (BehaviourComponent.IsInVisionCone(Target.ActorLocation, 400.f))
			return true;
		return false;
	}
}



