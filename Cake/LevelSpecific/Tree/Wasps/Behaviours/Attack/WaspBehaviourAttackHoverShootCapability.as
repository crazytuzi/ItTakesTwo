import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourAttackHoverShootCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Attack;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddNumber(n"ShootSalvo", BehaviourComponent.ShouldFireSalvo() ? 1 : 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		float AttackDuration = 0.1f;
		int NumShots = 1;

		if (ActivationParams.GetNumber(n"ShootSalvo") > 0)
		{
			NumShots = Settings.NumShotsInSalvo;
			AttackDuration = NumShots * Settings.SalvoShotInterval + 1.5f;
			BehaviourComponent.SingleShotsSinceSalvo = 0;
			AnimComp.PlayAnimation(EWaspAnim::ShootBurst);
			if (AnimComp.ShootingAnimFeature != nullptr) 
			{
				float AnimDuration = AnimComp.ShootingAnimFeature.GetSingleAnimation(EWaspAnim::ShootBurst, 0).Wasp.SequenceLength;
				if (AnimDuration > AttackDuration)
					AttackDuration = AnimDuration;
			}
		}
		else
		{
			BehaviourComponent.PerformSustainedAttack(Settings.SalvoShotInterval);
			BehaviourComponent.SingleShotsSinceSalvo++;
			AnimComp.PlayAnimation(EWaspAnim::ShootSingle);
			if (AnimComp.ShootingAnimFeature != nullptr) 
				AttackDuration = AnimComp.ShootingAnimFeature.GetSingleAnimation(EWaspAnim::ShootSingle, 0).Wasp.SequenceLength;
		}
		BehaviourComponent.PerformSustainedAttack(AttackDuration, NumShots);

		EffectsComp.ShowAttackEffect(BehaviourComponent.Target.FocusLocation);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Super::OnDeactivated(DeactivationParams);
        BehaviourComponent.StopSustainedAttack();
		AnimComp.StopAnimation(EWaspAnim::ShootSingle);
		AnimComp.StopAnimation(EWaspAnim::ShootBurst);
		EffectsComp.HideAttackEffect();
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

        if (ShouldRecover())
        {
            BehaviourComponent.State = EWaspState::Recover; 
            return;
        }

        // Stay in place, facing target
        BehaviourComponent.RotateTowards(BehaviourComponent.GetTarget().GetFocusLocation());
    }

    bool ShouldRecover()
    {
        // Have we lost target?
        if (!BehaviourComponent.HasValidTarget())
            return true;

        // Cease fire?
        if (Time::GetGameTimeSeconds() > BehaviourComponent.SustainedAttackEndTime) 
            return true;

        // Keep on coming!    
        return false;
    }
}

