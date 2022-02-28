import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetleShockWaveComponent;
import Vino.Movement.Components.MovementComponent;

class UBeetleBehaviourMultiSlamCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::MultiSlam;
	
	UBeetleShockwaveComponent ShockwaveComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		ShockwaveComp = UBeetleShockwaveComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		CheckActivation();
	}

	UFUNCTION()
	void OnTakeDamage(float RemainingHealth, AHazePlayerCharacter Attacker, float BatchDamage, const FVector& DamageDir)
	{
		CheckActivation();		
	}

	void CheckActivation()
	{
		if (HealthComp.GetHealthFraction() < Settings.MultiSlamStartHealthFraction + KINDA_SMALL_NUMBER)
		{
			// Time to start using this special attack. Very first special attack can be taken immediately.
			int NumCharges = (BehaviourComp.bHasPerformedSpecialAttack) ? 0 : Settings.MultiSlamInterval; 
			BehaviourComp.QueueSpecialAttack(EBeetleState::MultiSlam, NumCharges, 0.f, Settings.MultiSlamMaxRange);
			HealthComp.OnTakeDamage.Unbind(this, n"OnTakeDamage");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		BehaviourComp.UseAttackState(EBeetleState::MultiSlam);
		AnimComp.OnShockwaveNotify.AddUFunction(this, n"TriggerShockwave");
		AnimComp.PlayAnim(AnimFeature.MultiSlam, this, n"SlamAnimDone");

		// Since we didn't move we should attack same target again after this attack
		BehaviourComp.bKeepTarget = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		AnimComp.OnShockwaveNotify.Unbind(this, n"TriggerShockwave");

		if (!BehaviourComp.IsValidTarget(HealthComp.LastAttacker))
			HealthComp.LastAttacker = nullptr;
		HealthComp.SetUnsappable();

		// Set up next attack
		BehaviourComp.QueueSpecialAttack(EBeetleState::MultiSlam, Settings.MultiSlamInterval, 0.f, Settings.MultiSlamMaxRange);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't go near a slamming beetle
		BehaviourComp.CheckFullbodyImpact();
	}

	UFUNCTION()
	void TriggerShockwave()
	{
		ShockwaveComp.TriggerShockwave();
	}

	UFUNCTION()
	void SlamAnimDone()
	{
		if (IsActive())
		{
			if (Settings.bAdditionalAttackRecoveryWhenPlayerKilled && IAnyPlayerDead())
				BehaviourComp.State = EBeetleState::Recover;
			else
				BehaviourComp.State = EBeetleState::Pursue;
		}
	}	
}