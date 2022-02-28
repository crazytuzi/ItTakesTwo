import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;

class UWaspLocalBehaviourComponent : UWaspBehaviourComponent
{
	void SetState(EWaspState State) property override
	{
		// Allow state to be set regardless of control side 
		CurrentState = State; 
	}
}
