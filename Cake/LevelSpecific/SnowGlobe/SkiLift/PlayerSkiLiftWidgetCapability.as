import Cake.LevelSpecific.SnowGlobe.SkiLift.SkiLift;

class UPlayerSkiLiftWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(n"SnowGlobeSkiLiftWidget");

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	ASkiLift SkiLift;

	UHazeInputButton InteractionWidget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(n"SnowglobeSkiLift"))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(n"SnowglobeSkiLiftBarInteraction"))
			return EHazeNetworkActivation::DontActivate;

		if(GetAttributeObject(n"SkiLift") == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SkiLift = Cast<ASkiLift>(GetAttributeObject(n"SkiLift"));

		InteractionWidget = Cast<UHazeInputButton>(PlayerOwner.AddWidget(SkiLift.PlayerInteractionWidgetClass));
		InteractionWidget.ActionName = ActionNames::InteractionTrigger;
		InteractionWidget.AttachWidgetToComponent(PlayerOwner.Mesh, PlayerOwner.IsCody() ? n"RightHand" : n"LeftHand");
		InteractionWidget.SetWidgetRelativeAttachOffset(FVector(0.f, PlayerOwner.IsCody() ? 0.f : -0.f, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(n"SnowglobeSkiLift"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(PlayerOwner.IsAnyCapabilityActive(n"SnowglobeSkiLiftBarInteraction"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(GetAttributeObject(n"SkiLift") == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.RemoveWidget(InteractionWidget);
		InteractionWidget = nullptr;
		SkiLift = nullptr;
	}
}