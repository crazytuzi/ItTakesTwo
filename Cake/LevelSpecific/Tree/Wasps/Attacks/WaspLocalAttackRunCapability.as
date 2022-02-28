import Cake.LevelSpecific.Tree.Wasps.Attacks.WaspAttackRunCapability;

class UWaspLocalAttackRunCapability : UWaspAttackRunCapability
{
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == EHazeNetworkDeactivation::DontDeactivate)
            return EHazeNetworkDeactivation::DontDeactivate;
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
};
