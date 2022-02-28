import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;

class UBeetleBehaviourTelegraphCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Telegraphing;

	EBeetleState NextAttackState = EBeetleState::Attack;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		NextAttackState = BehaviourComp.SelectNextAttackState();
		ActivationParams.AddNumber(n"AttackState", NextAttackState);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		NextAttackState = EBeetleState(ActivationParams.GetNumber(n"AttackState"));
		UAnimSequence Anim = AnimFeature.TelegraphCharge;
		switch (NextAttackState)
		{
			case EBeetleState::Pounce:
				Anim = AnimFeature.TelegraphPounce;
				break;
			case EBeetleState::MultiSlam:
				Anim = AnimFeature.TelegraphMultiSlam;
				break;
		}
		AnimComp.PlayAnim(Anim, this, n"OnAnimComplete");
    }

	UFUNCTION()
	void OnAnimComplete()
	{
		if (IsActive())
			BehaviourComp.State = NextAttackState;
	}
}
