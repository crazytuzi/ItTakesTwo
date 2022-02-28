import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetleShockWaveComponent;

class UBeetleBehaviourEntranceCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Idle;
	bool bHasEntered = false;
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (bHasEntered)
			return EHazeNetworkActivation::DontActivate;
       	return Super::ShouldActivate();
	}
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		AnimComp.PlayAnim(AnimFeature.EntranceEnd, this, n"OnEntranceAnimComplete");
    }
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		Owner.StopAnimationByAsset(AnimFeature.Entrance);
		BehaviourComp.OnEntranceDone.Broadcast();
		UBeetleShockwaveComponent::Get(Owner).ShockWaveHeight = Owner.ActorLocation.Z;
	}
	UFUNCTION()
	void OnEntranceAnimComplete()
	{
		if (!IsActive())
			return;
		// Time to start chasing the players!
		BehaviourComp.State = EBeetleState::Pursue;
	}
}