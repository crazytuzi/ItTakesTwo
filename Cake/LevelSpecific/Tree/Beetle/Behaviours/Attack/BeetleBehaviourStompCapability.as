import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetleShockwaveComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class UBeetleBehaviourStompCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Stomp;
	
	UBeetleShockwaveComponent ShockwaveComp;
	bool bDealCollisionDamage = false;
	bool bInitialMomentum = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		ShockwaveComp = UBeetleShockwaveComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		HealthComp.SetSappable();
		BehaviourComp.ResetFullBodyImpact();
		bDealCollisionDamage = false;
		bInitialMomentum = true;
		AnimComp.OnShockwaveNotify.AddUFunction(this, n"TriggerShockwave");
		AnimComp.OnDealCollisionDamageBegin.AddUFunction(this, n"DealCollisionDamageBegin");
		AnimComp.OnDealCollisionDamageEnd.AddUFunction(this, n"DealCollisionDamageEnd");
		AnimComp.PlayAnim(AnimFeature.Stomp, this, n"StompAnimDone");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		if (!BehaviourComp.IsValidTarget(HealthComp.LastAttacker))
			HealthComp.LastAttacker = nullptr;
		HealthComp.SetUnsappable();
		AnimComp.OnShockwaveNotify.Unbind(this, n"TriggerShockwave");
		AnimComp.OnDealCollisionDamageBegin.Unbind(this, n"DealCollisionDamageBegin");
		AnimComp.OnDealCollisionDamageEnd.Unbind(this, n"DealCollisionDamageEnd");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bInitialMomentum)
			MoveDataComp.MoveTo(Owner.ActorLocation + Owner.ActorForwardVector * 1000.f, Settings.StraightChargeSpeed * 0.5f, 1000.f);

		if (bDealCollisionDamage)
		{
			// Check if we land on or otherwise hit a target
			BehaviourComp.CheckFullbodyImpact();
		}
	}

	UFUNCTION()
	void TriggerShockwave()
	{
		ShockwaveComp.TriggerShockwave();
		// Cut end of animation to increase pacing.
		// TODO: Remove when timing is set and animation fixed.
		System::SetTimer(this, n"StompAnimDone", 0.5f, false); 
	}

	UFUNCTION()
	void StompAnimDone()
	{
		if (IsActive())
		{
			if (Settings.bAdditionalAttackRecoveryWhenPlayerKilled && IAnyPlayerDead())
				BehaviourComp.State = EBeetleState::Recover;
			else
				BehaviourComp.State = EBeetleState::Pursue;
		}
	}

	UFUNCTION()
	void DealCollisionDamageBegin()
	{
		bDealCollisionDamage = true;
	}

	UFUNCTION()
	void DealCollisionDamageEnd()
	{
		bDealCollisionDamage = false;
		bInitialMomentum = false;
	}
}