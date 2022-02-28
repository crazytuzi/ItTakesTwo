import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourPostAttackPauseCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Recover;
    default SetPriority(EWaspBehaviourPriority::High);

    float RecoverTime = 0.f;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
		if (BehaviourComponent.PreviousState != EWaspState::Attack)
    		return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
        RecoverTime = Time::GetGameTimeSeconds() + Settings.RecoverDuration * 0.5f;

        UGentlemanFightingComponent GentlemanComp = BehaviourComponent.GetGentlemanComponent();
        if (GentlemanComp != nullptr)  
            GentlemanComp.ReleaseAction(n"WaspAttack", Owner);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        if (HealthComp.IsSapped())
        {
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

        if (Time::GetGameTimeSeconds() > RecoverTime)
        {
            BehaviourComponent.State = EWaspState::Idle;
            return;
        }

        // No move, just drift to a stop
        AHazeActor Target = BehaviourComponent.GetTarget();
        if (BehaviourComponent.IsValidTarget(Target))
            BehaviourComponent.RotateTowards(Target.GetFocusLocation());
    }
}
