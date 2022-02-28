import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;

class UBeetleBehaviourRecoverCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Recover;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		AnimComp.PlayAnim(AnimFeature.Recover, this, n"OnAnimComplete");
    }

	UFUNCTION()
	void OnAnimComplete()
	{
		if (IsActive())
			BehaviourComp.State = EBeetleState::Pursue;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float  DeltaTime)
	{
		// Don't disturb a resting beetle!
		if ((BehaviourComp.StateDuration > 1.f) && (Time::GetGameTimeSince(HealthComp.LastAttackedTime) < 1.f))
			BehaviourComp.State = EBeetleState::Pursue;
	}
}