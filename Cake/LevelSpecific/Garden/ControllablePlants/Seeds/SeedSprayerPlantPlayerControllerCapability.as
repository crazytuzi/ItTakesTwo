import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerPlant;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;
import Cake.LevelSpecific.Garden.ControllablePlants.PlayerExitPlantCapability;
import Vino.Tutorial.TutorialStatics;

class USeedSprayerPlantPlayerControllerCapability : UPlayerExitPlantCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = ECapabilityTickGroups::Input;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	UPROPERTY()
	FText ExitSoilText = NSLOCTEXT("Plants", "Name", "Exit Soil");

	AHazePlayerCharacter PlayerOwner;
	UControllablePlantsComponent PlantsComponent;
	ASeedSprayerPlant Plant;
	USeedSprayerWitherSimulationContainerComponent ColorContainerComponent;
	bool bHasBeenActivatedWhenFullyPlanted = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlantsComponent = UControllablePlantsComponent::Get(PlayerOwner);
		ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const override
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		auto WantedPlant = Cast<ASeedSprayerPlant>(PlantsComponent.CurrentPlant);
		if(WantedPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const override
	{
		if(Plant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		ASeedSprayerPlant CurrentPlant = Cast<ASeedSprayerPlant>(PlantsComponent.CurrentPlant);
		if(Plant != CurrentPlant)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ColorContainerComponent.ActiveSoil == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ColorContainerComponent.ActiveSoil.bHasBeenFullyPlanted && !bHasBeenActivatedWhenFullyPlanted)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"ExitPlant", true);
		Plant = Cast<ASeedSprayerPlant>(PlantsComponent.CurrentPlant);
		bHasBeenActivatedWhenFullyPlanted = ColorContainerComponent.ActiveSoil.bHasBeenFullyPlanted;
		ShowCancelPromptWithText(PlayerOwner, this, ExitSoilText);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		SetMutuallyExclusive(n"ExitPlant", false);
		RemoveCancelPromptByInstigator(PlayerOwner, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) override
	{
		const FVector WorldUp = PlayerOwner.GetMovementWorldUp();
		const FRotator ControlRotation = PlayerOwner.GetControlRotation();

		FVector Forward = ControlRotation.ForwardVector.ConstrainToPlane(WorldUp).GetSafeNormal();
		if (Forward.IsZero())
		{
			Forward = ControlRotation.UpVector.ConstrainToPlane(WorldUp).GetSafeNormal();
		}
		
		const FVector Right = WorldUp.CrossProduct(Forward);

		const FVector RawStick = GetAttributeVector(AttributeVectorNames::MovementRaw);
		const FVector Input = Forward * RawStick.X + Right * RawStick.Y;

		Plant.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, Input);

		Super::TickActive(DeltaTime);
	}
}