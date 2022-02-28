import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerPlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

enum ECodyFlowerType
{
	TypeOne,
	TypeTwo,
	TypeThree
}

class USeedSprayerCodyPlantCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = ECapabilityTickGroups::Input;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroupOrder = 50;

	AHazePlayerCharacter PlayerOwner;
	ASeedSprayerPlant Plant;
	UControllablePlantsComponent PlantsComponent;
	USeedSprayerWitherSimulationContainerComponent ColorContainerComponent;
	UHazeCrumbComponent CrumbComponent;

	// The size the input flower paints with
	const float PlantRadius = 550.f;

	// The size the movement paints withs	
	const float PassivePlantRadius = 400.f;

	const bool bRequireWaterToPaint = false;

	ECodyFlowerType CurrentFlowerType = ECodyFlowerType::TypeThree;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlantsComponent = UControllablePlantsComponent::Get(PlayerOwner);
		ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlantsComponent.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlantsComponent.CurrentPlant.IsA(ASeedSprayerPlant::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if(ColorContainerComponent.ColorSystem == nullptr)
			return EHazeNetworkActivation::DontActivate;	
		
		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ColorContainerComponent.ColorSystem == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(PlantsComponent.CurrentPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!PlantsComponent.CurrentPlant.IsA(ASeedSprayerPlant::StaticClass()))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Plant = Cast<ASeedSprayerPlant>(PlantsComponent.CurrentPlant);
		if(!ColorContainerComponent.ActiveSoil.bHasBeenFullyPlanted)
		{
			ColorContainerComponent.ActiveSoil.FullyPlanted.AddUFunction(this, n"OnFullyPlanted");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
			
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ColorContainerComponent.ActiveSoil != nullptr && !ColorContainerComponent.ActiveSoil.bHasBeenFullyPlanted)
		{
			bool bPainted = false;
			if(CurrentFlowerType == ECodyFlowerType::TypeOne)
			{
				bPainted = ColorContainerComponent.ColorSystem.PaintFlowerTypeOneOnLocation(PlayerOwner.GetActorLocation(), PlantRadius, bRequireWaterToPaint);
			}
			else if(CurrentFlowerType == ECodyFlowerType::TypeTwo)
			{	
				bPainted = ColorContainerComponent.ColorSystem.PaintFlowerTypeTwoOnLocation(PlayerOwner.GetActorLocation(), PlantRadius, bRequireWaterToPaint);
			}
			else
			{
				bPainted = ColorContainerComponent.ColorSystem.PaintFlowerTypeThreeOnLocation(PlayerOwner.GetActorLocation(), PassivePlantRadius, bRequireWaterToPaint);
			}

			if(bPainted)
			{
				ColorContainerComponent.ColorSystem.UpdateFullyPlanted(ColorContainerComponent.ActiveSoil);
				ColorContainerComponent.ColorSystem.UpdatePercentageEvents(ColorContainerComponent.ActiveSoil);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnFullyPlanted(ASubmersibleSoilPlantSprayer Area)
	{
		if(Plant != nullptr)
		{
			Plant.ExitPlant();
			if(Plant.FullyPlantedDeactivateEffect != nullptr)
		 		Niagara::SpawnSystemAtLocation(Plant.FullyPlantedDeactivateEffect, Plant.GetActorCenterLocation());
		}
	}
}