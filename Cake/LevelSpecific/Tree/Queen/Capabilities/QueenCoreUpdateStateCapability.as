
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;

UCLASS()
class UQueenCoreUpdateStateCapability : UQueenBaseCapability 
{
	default CapabilityTags.Add(n"QueenCore");
	default CapabilityTags.Add(n"QueenUpdateState");

	int PrevNumSwarms = -1;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.BehaviourComp.Swarms.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.BehaviourComp.Swarms.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UpdateQueenState();
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UpdateQueenState();
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		UpdateQueenState();
    }

	void UpdateQueenState()
	{
		if (IsActioning(n"SpawnNoWasps"))
		{
			ConsumeAction(n"SpawnNoWasps");
			Queen.BehaviourComp.State = EQueenManagerState::None;
		}

		int NumSwarms = Queen.BehaviourComp.Swarms.Num();
		if(NumSwarms != PrevNumSwarms)
			Queen.BehaviourComp.State = EQueenManagerState(NumSwarms);
		PrevNumSwarms = NumSwarms;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString Str = "Swarm Queen State";

		Str += "\n";
		Str += "\n";

		Str += "State Current: <Yellow>";
		Str += GetQueenDebugStateName(Queen.BehaviourComp.State);
		Str += "</>";

		Str += "\n";
		return Str;
	}
}