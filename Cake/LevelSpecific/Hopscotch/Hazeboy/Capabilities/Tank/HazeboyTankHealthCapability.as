import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class UHazeboyTankHealthCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	AHazeboyTank Tank;
	float HoldTime = 0.f;
	int CurrentHealth = 3;

	UHazeboyHealthWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HazeboyGameIsActive() && !HazeboyGameHasEnded())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HazeboyGameIsActive() && !HazeboyGameHasEnded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Widget = Cast<UHazeboyHealthWidget>(Tank.Camera.AddWidget(Tank.HealthWidgetClass, 50.f));

		CurrentHealth = 3;
		Widget.SetHealth(CurrentHealth);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Tank.Camera.RemoveWidget(Widget);
		Widget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Tank.Health != CurrentHealth)
		{
			CurrentHealth = Tank.Health;
			Widget.SetHealth(CurrentHealth);
		}
	}
}