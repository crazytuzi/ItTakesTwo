import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetlePlayerDamageEffect;

class UBeetleBehaviourGoreCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Gore;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		AnimComp.PlayAnim(AnimFeature.Gore, BehaviourComp, n"OnGoreComplete");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		if (!BehaviourComp.IsValidTarget(HealthComp.LastAttacker))
			HealthComp.LastAttacker = nullptr;
		BehaviourComp.GoreCompleteTime = BIG_NUMBER;	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Slide forward for a while
		if (BehaviourComp.StateDuration < 0.5f)
			MoveDataComp.MoveTo(Owner.ActorLocation + Owner.ActorForwardVector * 1000.f, Settings.HomingChargeSpeed * 0.5f, 1000.f);
		if (Time::GetGameTimeSeconds() > BehaviourComp.GoreCompleteTime)	
			BehaviourComp.State = EBeetleState::Recover;
	}
}