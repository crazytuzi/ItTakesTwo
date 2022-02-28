
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;

UCLASS()
class UQueenUpdateBehaviourCapability : UQueenBaseCapability 
{
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

}