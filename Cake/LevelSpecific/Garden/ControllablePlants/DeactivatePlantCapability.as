import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

class UDeactivatePlantCapability : UHazeCapability
{
	UControllablePlantsComponent PlantsComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantsComp = UControllablePlantsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!PlantsComp.bDeactivatePlant)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlantsComp.CurrentPlant.TriggerCameraTransitionToPlayer();
		PlantsComp.bDeactivatePlant = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
