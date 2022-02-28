import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthAudioComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthSettings;

class UPlayerRespawnHUDCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"Health";
	default CapabilityTags.Add(n"RespawnTimerHUD");

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UPlayerHealthAudioComponent AudioHealthComp;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthSettings HealthSettings;

	UHazeUserWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!RespawnComp.bWaitingForRespawn)
			return EHazeNetworkActivation::DontActivate;
		if (RespawnComp.bIsGameOver)
			return EHazeNetworkActivation::DontActivate;
		if (SceneView::IsFullScreen())
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!RespawnComp.bWaitingForRespawn)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (RespawnComp.bIsGameOver)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (SceneView::IsFullScreen())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::Slow, EHazeViewPointPriority::Low);
		Player.ApplyCameraSettings(RespawnComp.CameraSettingsWhileDead, FHazeCameraBlendSettings(), this);

		UClass WidgetClass = RespawnComp.WaitRespawnWidget.Get();
		if (WidgetClass != nullptr)
		{
			Widget = Player.AddWidget(WidgetClass, EHazeWidgetLayer::PlayerHUD);
			AudioHealthComp.bRespawnWidgetActive = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Slow);
		Player.ClearCameraSettingsByInstigator(this);

		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
			AudioHealthComp.bRespawnWidgetActive = false;
		}
	}
};