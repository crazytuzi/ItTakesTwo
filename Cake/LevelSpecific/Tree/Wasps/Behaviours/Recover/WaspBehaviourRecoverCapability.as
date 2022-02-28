import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourRecoverCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Recover;

    float RecoverHeight = 0.f;
    float RecoverTime = 0.f;
	float ExhaustedTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        RecoverHeight = Owner.GetActorLocation().Z + Settings.RecoverHeight;
        RecoverTime = Time::GetGameTimeSeconds() + Settings.RecoverDuration;
		if (BehaviourComponent.PreviousState == EWaspState::Stunned)
	        RecoverTime = Time::GetGameTimeSeconds() + Settings.PostStunRecoverDuration;

        UGentlemanFightingComponent GentlemanComp = BehaviourComponent.GetGentlemanComponent();
        if (GentlemanComp != nullptr)  
            GentlemanComp.ReleaseAction(n"WaspAttack", Owner);

		if (Settings.ExhaustedTime > 0.f)
		{
			ExhaustedTime = Time::GameTimeSeconds + 0.5f;
			RecoverTime += Settings.ExhaustedTime;
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		if (Settings.ExhaustedTime > 0.f)
			AnimComp.StopAnimation(EWaspAnim::Exhausted);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        // Only react to saps some time into recovery
        if (HealthComp.IsSapped() && 
            (BehaviourComponent.GetStateDuration() > 2.f))
        {
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

		float CurTime = Time::GetGameTimeSeconds();
        if (CurTime > RecoverTime)
        {
            BehaviourComponent.State = EWaspState::Idle;
            return;
        }

        FVector OwnLoc = Owner.GetActorLocation();
        FVector Destination = OwnLoc;
        if (CurTime < RecoverTime - 2.f)
             Destination += Owner.GetActorForwardVector() * 1000.f;
        
        Destination.Z = RecoverHeight;
        BehaviourComponent.MoveTo(Destination, FMath::Max(Settings.RecoverAcceleration * (RecoverHeight - OwnLoc.Z - 100.f), 0.f));
		BehaviourComponent.RotateTowards(OwnLoc + Owner.GetActorForwardVector() * 1000.f);

		if ((ExhaustedTime > 0.f) && (CurTime > ExhaustedTime))
		{
			AnimComp.PlayAnimation(EWaspAnim::Exhausted, 0.5f);
			if ((BehaviourComponent.ExhaustedFailBark != nullptr) && (Time::GetGameTimeSince(BehaviourComponent.LastAttackRunHitTime) > 10.f))
				PlayFoghornBark(BehaviourComponent.ExhaustedFailBark, Owner); 
			ExhaustedTime = 0.f;
		}
		if ((Settings.ExhaustedTime > 0.f) && (CurTime > RecoverTime - 1.f))
			AnimComp.StopAnimation(EWaspAnim::Exhausted);
    }
}
