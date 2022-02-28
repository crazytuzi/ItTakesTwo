import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourStunnedCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Stunned;

    float StunnedHeight = 0.f;
    float MinRecoverTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
        StunnedHeight = Owner.GetActorLocation().Z - Settings.StunnedFallHeight;
		MinRecoverTime = Time::GetGameTimeSeconds() + Settings.StunnedDuration;

        UGentlemanFightingComponent GentlemanComp = BehaviourComponent.GetGentlemanComponent();
        if (GentlemanComp != nullptr)  
            GentlemanComp.ReleaseAction(n"WaspAttack", Owner);

		EffectsComp.FlashTime = 0.f;
		HealthComp.bShouldRemoveSap = true;
		BehaviourComponent.AbortQuickAttackSequence();
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		HealthComp.bShouldRemoveSap = false;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        float CurTime = Time::GetGameTimeSeconds();
        if ((CurTime > MinRecoverTime) && 
            FMath::IsNearlyZero(HealthComp.SapMass))
        {
			if (BehaviourComponent.bFleeAfterStun)
	            BehaviourComponent.State = EWaspState::Flee;	
			else
            	BehaviourComponent.State = EWaspState::Recover;
            return;
        }

		HealthComp.bShouldRemoveSap = true;
        FVector Destination = Owner.GetActorLocation();
        if (Destination.Z > StunnedHeight)
        {
            Destination.Z = StunnedHeight;
            BehaviourComponent.MoveTo(Destination, Settings.StunAcceleration);
			BehaviourComponent.RotateTowards(Owner.ActorLocation + Owner.ActorForwardVector * 1000.f);
        }
    }
}
