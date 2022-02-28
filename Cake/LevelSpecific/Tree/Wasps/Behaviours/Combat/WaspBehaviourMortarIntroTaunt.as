import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;

class UWaspBehaviourMortarIntroTauntCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Combat;
    default SetPriority(EWaspBehaviourPriority::Maximum);

	bool bTauntAnimComplete = false; 
	
	UFUNCTION(BlueprintOverride) 
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
        if (BehaviourComponent.bHasSpotEnemyTaunted)
                return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (bTauntAnimComplete)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		bTauntAnimComplete = false;
		AnimComp.PlayAnimation(EWaspAnim::InitialTaunt);
		BehaviourComponent.bHasSpotEnemyTaunted = true; 

		// Hack: stop animation early
		System::SetTimer(this, n"OnTauntDone", 1.25f, false);

		if (BehaviourComponent.IntroBark != nullptr)
			PlayFoghornBark(BehaviourComponent.IntroBark, Owner);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (BehaviourComponent.HasValidTarget())
        {
			AHazeActor Target = BehaviourComponent.GetTarget();
			BehaviourComponent.RotateTowards(Target.GetActorLocation());
        }
    }

	UFUNCTION()
	void OnTauntDone()
	{
		AnimComp.StopAnimation(EWaspAnim::InitialTaunt, 0.5f);
		bTauntAnimComplete = true; 
	}	
}
