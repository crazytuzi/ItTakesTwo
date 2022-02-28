import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceComponent;

class UIceRaceWidgetCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"IceRace";

	default CapabilityTags.Add(n"IceRace");
	default CapabilityTags.Add(n"IceRaceWidget");

	UIceRaceComponent IceRaceComponent;
	AHazePlayerCharacter Player;

	UIceRaceWidget IceRaceWidget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		IceRaceComponent = UIceRaceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Player.IsMay())
			return EHazeNetworkActivation::DontActivate;

		if(!IceRaceComponent.bRaceActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IceRaceComponent.bRaceActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		IceRaceWidget = Cast<UIceRaceWidget>(Widget::AddFullscreenWidget(IceRaceComponent.IceRaceWidget));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget::RemoveFullscreenWidget(IceRaceWidget);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}