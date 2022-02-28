import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourAttackStrafeShootCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Attack;

    bool StrafeRight = false;
	float StrafeDirectionChangeTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddNumber(n"ShootSalvo", BehaviourComponent.ShouldFireSalvo() ? 1 : 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		if (Time::GetGameTimeSeconds() > StrafeDirectionChangeTime)
		{
			StrafeRight = !StrafeRight;
			StrafeDirectionChangeTime = Time::GetGameTimeSeconds() + 5.f;
		}

		float AttackDuration = 0.1f;
		int NumShots = 1;

		if (ActivationParams.GetNumber(n"ShootSalvo") > 0)
		{
			NumShots = Settings.NumShotsInSalvo;
			AttackDuration = NumShots * Settings.SalvoShotInterval + 0.5f;
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
		AnimComp.StopAnimation(EWaspAnim::Hover, 0.3f);
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

        // Strafe around target
        FVector TargetLoc = BehaviourComponent.GetTarget().GetActorLocation();
        FVector StrafeDir = Owner.GetActorRightVector() * (StrafeRight ? 1.f : -1.f);
        float CircleDistance = 0.5f * (Settings.EngageMinDistance + Settings.EngageMaxDistance);
        FVector StrafeDest = BehaviourComponent.GetCirclingDestination(TargetLoc, Settings.EngageHeight, StrafeDir, CircleDistance);
        BehaviourComponent.MoveTo(StrafeDest, Settings.AttackRunAcceleration);
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

