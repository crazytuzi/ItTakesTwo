import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourTauntCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Telegraphing;
	default bExclusive = false;	

    int8 TauntIndex = 0;
	bool bPlayExposedTaunt = false;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;

        if (AnimComp.AnimFeature.Taunts.Num() == 0)
    		return EHazeNetworkActivation::DontActivate;
 
        // Wait a while after coming into attack position before starting taunt
        if (BehaviourComponent.StateDuration < Settings.PrepareAttackDuration - Settings.TauntDuration)
            return EHazeNetworkActivation::DontActivate;
			
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// To support randomized taunts
        ActivationParams.AddNumber(n"TauntIndex", (TauntIndex + 1) % AnimComp.AnimFeature.Taunts.Num());                
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		TauntIndex = ActivationParams.GetNumber(n"TauntIndex");
		AnimComp.PlayAnimation(EWaspAnim::Taunts, TauntIndex, 0.2f);
		if (Settings.bEnemyIndicatorHighlightWhenTelegraphing)
			EffectsComp.ShowAttackEffect(BehaviourComponent.Target.FocusLocation);

		bPlayExposedTaunt = Settings.bExposedTauntAfterRegular;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		if (!HealthComp.bIsDead)
 			Owner.SetActorHiddenInGame(false);
		if (Settings.bEnemyIndicatorHighlightWhenTelegraphing)
			EffectsComp.HideAttackEffect();
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (!BehaviourComponent.HasValidTarget())
			return;

        BehaviourComponent.RotateTowards(BehaviourComponent.Target.GetFocusLocation());
		
		if (Time::GetGameTimeSince(BehaviourComponent.StateChangeTime) > 1.5f)
			EffectsComp.FlashTime = Time::GetGameTimeSeconds() + 1.f;

		if (bPlayExposedTaunt && (AnimComp.CurrentAnim == EWaspAnim::None))
		{
			// Play exposed taunt after regular taunt once.
			AnimComp.PlayAnimation(EWaspAnim::TauntExposed);
			bPlayExposedTaunt = false;
		}
    }
}

