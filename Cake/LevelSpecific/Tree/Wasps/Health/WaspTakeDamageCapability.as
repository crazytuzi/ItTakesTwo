import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;

class UWaspTakeDamageCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Damage");

	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	UWaspBehaviourComponent BehaviourComp;
	UWaspHealthComponent HealthComp;
	UWaspAnimationComponent AnimComp;
	UWaspComposableSettings Settings;

	float HurtOverTime = 0.f;
	AHazeActor NextTarget = nullptr;
	EWaspState ExitState = EWaspState::Idle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HealthComp = UWaspHealthComponent::Get(Owner);
		AnimComp = UWaspAnimationComponent::Get(Owner);
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate; // The dead feel no pain
		if (!HealthComp.bIsHurt)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (HealthComp.bIsDead)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!HealthComp.bIsHurt)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Time::GetGameTimeSeconds() > HurtOverTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// No conscious behaviour while reeling from damage
		Owner.BlockCapabilities(n"WaspBehaviour", this);

		// Stop any threeshots and attacks as well
		Owner.BlockCapabilities(n"WaspAnimationThreeShot", this);
		Owner.BlockCapabilities(n"Attack", this);
	
		if (!HasControl())
			HealthComp.bIsHurt = true;
		
		AnimComp.PlayAnimation(EWaspAnim::TakeDamage, 0.1f);
		if (BehaviourComp.TakeDamageBark != nullptr)
			PlayFoghornBark(BehaviourComp.TakeDamageBark, Owner);

		// Stop hurting after a while
		float HurtDuration = 2.f;
		if (AnimComp.AnimFeature.TakeDamage != nullptr)
			HurtDuration = AnimComp.AnimFeature.TakeDamage.GetPlayLength();
		else if ((AnimComp.ShootingAnimFeature != nullptr) && (AnimComp.ShootingAnimFeature.TakeDamage.Wasp != nullptr))
			HurtDuration = AnimComp.ShootingAnimFeature.TakeDamage.Wasp.GetPlayLength();
		HurtOverTime = Time::GetGameTimeSeconds() + HurtDuration;
		ExitState = Settings.PostDamageState;

		// In case damage interrupted a completed attack sequence, we should allow 
		// wasp to find a new target before proceeding to next state
		if ((ExitState != EWaspState::Idle) && HasCompletedAttack())
		{
			// Exit into idle state, so we'll start by finding a new target,
			// then make sure the find target behaviour will exit into our wanted 
			// exit state. This ensures we won't mess up control side switching etc.
			BehaviourComp.FindTargetExitState = ExitState;
			ExitState = EWaspState::Idle;
		}

		BehaviourComp.AbortQuickAttackSequence();

		// Can't be sapped while thrashing about
		HealthComp.SetSappable(false, this);

		if (Settings.bFaceTargetWhenHurt)
		{
			// Guess what our next target will be. It's not terribly important 
			// we get this right, but nice.
			NextTarget = BehaviourComp.Target;
			if (ExitState == EWaspState::Idle)
			{
				// We'll have a chance to switch target
				if (BehaviourComp.IsValidTarget(BehaviourComp.AggroTarget))
					NextTarget = BehaviourComp.AggroTarget;
				else if (Settings.TargetSelection == EWaspTargetSelection::Alternate)
					NextTarget = (NextTarget == Game::Cody ? Game::May : Game::Cody);
			}
			if (!BehaviourComp.IsValidTarget(NextTarget))
				NextTarget = BehaviourComp.LastAttackedTarget;
			if (!BehaviourComp.IsValidTarget(NextTarget))
				NextTarget = Game::Cody;
		}
	}

	bool HasCompletedAttack()
	{
		// If we're in a quick attack sequence, we're not done until last attack has started.
		if ((Settings.NumQuickAttacks > 0) && (BehaviourComp.QuickAttackSequenceCount > 0))
			return false;
		if (BehaviourComp.State == EWaspState::Recover)
			return true; // Attack completed
		if (BehaviourComp.State == EWaspState::Attack)
			return true; // Attack started, count as completed
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Settings.bFaceTargetWhenHurt && (NextTarget != nullptr))
		{
			BehaviourComp.RotateTowards(NextTarget.FocusLocation);
		}
		else
		{
			// Maintain rotation
			BehaviourComp.RotateTowards(Owner.ActorLocation + Owner.ActorForwardVector * 1000.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HealthComp.bIsHurt = false;
		if (!HealthComp.bIsDead)
			BehaviourComp.State = ExitState; 
		Owner.UnblockCapabilities(n"WaspBehaviour", this);
		Owner.UnblockCapabilities(n"WaspAnimationThreeShot", this);
		Owner.UnblockCapabilities(n"Attack", this);
		HealthComp.SetSappable(true, this);
	}
}