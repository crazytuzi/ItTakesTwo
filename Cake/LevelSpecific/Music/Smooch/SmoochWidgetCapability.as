import Cake.LevelSpecific.Music.Smooch.Smooch;
import Cake.LevelSpecific.Music.Smooch.SmoochNames;

class USmoochWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(Smooch::Smooch);
	default CapabilityDebugCategory = n"Smooch";
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;
	USmoochUserComponent SmoochComp;
	USmoochHoldWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsMay())
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SmoochComp.Progress = 0.f;
		Widget = Cast<USmoochHoldWidget>(Widget::AddFullscreenWidget(SmoochComp.HoldWidgetType));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget::RemoveFullscreenWidget(Widget);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Widget.SmoochProgress = SmoochComp.Progress;
	}
}
