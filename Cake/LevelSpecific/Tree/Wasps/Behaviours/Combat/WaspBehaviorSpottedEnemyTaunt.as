import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;

class UWaspBehaviourSpottedEnemyTauntCapability : UWaspBehaviourCapability
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
		FHazeAnimationDelegate AnimDone;
		AnimDone.BindUFunction(this, n"OnTauntDone");
		ULocomotionFeatureHeroWasp AnimFeature = ULocomotionFeatureHeroWasp::Get(Cast<AHazeCharacter>(Owner));

		Owner.PlaySlotAnimation(Animation = AnimFeature.Taunts[0], OnBlendingOut = AnimDone);
		BehaviourComponent.bHasSpotEnemyTaunted = true; 

		if (BehaviourComponent.IntroBark != nullptr)
			PlayFoghornBark(BehaviourComponent.IntroBark, Owner);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (HealthComp.IsSapped())
        {
            // Sapped!
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

        if (!BehaviourComponent.HasValidTarget())
        {
            // Lost target
            BehaviourComponent.State = EWaspState::Idle; 
            return;
        }

        AHazeActor Target = BehaviourComponent.GetTarget();
		BehaviourComponent.RotateTowards(Target.GetActorLocation());
    }


	UFUNCTION()
	void OnTauntDone()
	{
		bTauntAnimComplete = true; 
	}	
}
