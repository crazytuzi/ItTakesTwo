import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

UCLASS(Deprecated)
class UActivatePlantCapability : UHazeCapability
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
		//if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		//if (!PlantsComp.TargetPlantClass.IsValid())
		//	return EHazeNetworkActivation::DontActivate;
        
        //return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"PlantClass", PlantsComp.TargetPlantClass.Get());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TSubclassOf<AControllablePlant> PlantClass = Cast<UClass>(ActivationParams.GetObject(n"PlantClass"));
		PlantsComp.ActivatePlant(PlantClass);
		PlantsComp.ClearTargetPlantClass();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
