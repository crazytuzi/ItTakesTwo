import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

/*
	Listen to input from the player that will tell the controllable plant to exit.
*/

class UPlayerExitPlantCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"ExitPlant");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

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

		if(!PlantsComp.CurrentPlant.CanExitPlant())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WasActionStarted(ActionNames::Cancel) && PlantsComp.CanExitPlant())
		{
			PlantsComp.CurrentPlant.ExitPlant();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!PlantsComp.CurrentPlant.CanExitPlant())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}