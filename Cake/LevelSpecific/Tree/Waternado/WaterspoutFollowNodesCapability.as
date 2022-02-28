import Cake.LevelSpecific.Tree.Waternado.Waternado;
import Cake.LevelSpecific.Tree.Waternado.WaternadoNode;

class UWaternadoFollowNodeCapability : UHazeCapability 
{
	default CapabilityTags.Add(n"Waternado");
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AWaternado Waternado = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Waternado = Cast<AWaternado>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Waternado.MoveComp.CurrentNode == nullptr)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Waternado.MoveComp.CurrentNode == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(const float Dt)
 	{
	}

}

