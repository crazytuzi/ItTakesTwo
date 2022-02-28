import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;
import Rice.Math.MathStatics;

class UHazeboyTankTitleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazeboyTank Tank;
	AHazeboyTitleWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);

		TSubclassOf<UUserWidget> WidgetClass = Tank.TitleWidgetClass;
		Widget = Cast<AHazeboyTitleWidget>(Tank.Camera.AddWidget(WidgetClass, 40.f));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!(HazeboyIsTitleScreen() || HazeboyGameHasEnded()))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!(HazeboyIsTitleScreen() || HazeboyGameHasEnded()))
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Widget.OnShowTitleScreen();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget.OnHideTitleScreen();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Widget.bWaitingForOpponent = (Tank.OwningPlayer != nullptr);
	}
}