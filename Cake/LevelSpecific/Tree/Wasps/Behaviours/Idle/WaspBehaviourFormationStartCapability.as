import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspLocalBehaviourCapability;

class UWaspBehaviourFormationStartCapability : UWaspLocalBehaviourCapability
{
    default State = EWaspState::Idle;
	default SetPriority(EWaspBehaviourPriority::Low);

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		// Go to combat as soon as we have a scenepoint
		if (BehaviourComponent.CurrentScenepoint != nullptr)
	        BehaviourComponent.State = EWaspState::Combat;
    }
}
