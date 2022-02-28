import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourRecoverCapability : UFishBehaviourCapability
{
    default State = EFishState::Recover;

    float RecoverHeight = 0.f;
    float RecoverTime = 0.f;
	bool bBankRight = false;

	AHazeActor PrevTarget;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		PrevTarget = BehaviourComponent.Target;
        RecoverTime = Time::GetGameTimeSeconds() + Settings.RecoverDuration;
		bBankRight = !bBankRight;
		AnimComp.SetGapingPercentage(0.f);
		AnimComp.SetAgitated(false);

		if (BehaviourComponent.PreviousState == EFishState::Combat)
			EffectsComp.SetEffectsMode(EFishEffectsMode::Searching);
		else if (!BehaviourComponent.CanHuntTarget(PrevTarget))
			EffectsComp.SetEffectsMode(EFishEffectsMode::Searching);

		// Forget about target
		BehaviourComponent.SetTarget(nullptr);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        if (Time::GetGameTimeSeconds() > RecoverTime)
        {
            BehaviourComponent.State = EFishState::Idle;
            return;
        }

		if (!BehaviourComponent.CanHuntTarget(PrevTarget))
        {
            // Lost target, drift to a stop
            return;
        }

        FVector OwnLoc = Owner.GetActorLocation();
        FVector Destination = OwnLoc + BehaviourComponent.MawForwardVector.GetSafeNormal2D() * 2000.f;
		Destination += Owner.ActorRightVector * (bBankRight ? 1.f : -1.f) * 200.f * DeltaSeconds;
        BehaviourComponent.MoveTo(Destination, Settings.RecoverAcceleration, Settings.RecoverTurnDuration);
    }
}
