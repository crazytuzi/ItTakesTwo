import Peanuts.Outlines.Outlines;
import Vino.Camera.Components.CameraUserComponent;
import Vino.PlayerMarker.PlayerMarkerStatics;
import Vino.Camera.Capabilities.CameraTags;
import Cake.Orientation.OtherPlayerIndicatorSettings;
import Vino.PlayerHealth.PlayerHealthStatics;

class UFindOtherPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CameraTags::FindOtherPlayer);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	UCameraUserComponent User;
	AHazePlayerCharacter Player;
	AHazePlayerCharacter OtherPlayer;
	UPlayerRespawnComponent OtherPlayerRespawnComp;
	UOtherPlayerIndicatorSettings Settings;

	float TurnCameraTime = 0.f;
	float ApplySettingsTime = 0.f;
	FHazeAcceleratedRotator Rotation;
	float TurnDelay = 0.f;
	
	float TurnDuration = 0.45f;
	float SettingsDuration = 0.5f;
	float SettingsBlendInDuration = 0.2f;
	float SettingsBlendOutDuration = 2.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		User = UCameraUserComponent::Get(Owner);
		InitOtherPlayer();

		Settings = UOtherPlayerIndicatorSettings::GetSettings(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	void InitOtherPlayer()
	{
		OtherPlayer = Player.GetOtherPlayer();
		if (OtherPlayer == nullptr)
		{
			System::SetTimer(this, n"InitOtherPlayer", 0.5f, false);
			return;
		}

		OtherPlayerRespawnComp = UPlayerRespawnComponent::Get(OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(ActionNames::FindOtherPlayer))
		 	return EHazeNetworkActivation::DontActivate;
		if ((OtherPlayer == nullptr) || (OtherPlayerRespawnComp == nullptr))
		 	return EHazeNetworkActivation::DontActivate;
		if (IsPlayerDead(OtherPlayer))
		 	return EHazeNetworkActivation::DontActivate;
		if (OtherPlayerRespawnComp.bIsRespawning)
		 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(ActionNames::FindOtherPlayer))
			return EHazeNetworkDeactivation::DontDeactivate;
		if (OtherPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (IsPlayerDead(OtherPlayer))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (OtherPlayerRespawnComp.bIsRespawning)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (User.IsAiming())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Time::GetRealTimeSince(TurnCameraTime) > TurnDelay + TurnDuration + 0.5f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		FVector ToOther = (GetOtherPlayerIndicatorLocation() - Player.ViewLocation).GetSafeNormal();
		if (Player.ViewRotation.Vector().DotProduct(ToOther) > 0.999f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);

		OtherPlayer = Player.GetOtherPlayer(); 
		OtherPlayerRespawnComp = UPlayerRespawnComponent::Get(OtherPlayer);
		ForceEnablePlayerMarker(OtherPlayer, this);
		TurnCameraTime = Time::GetRealTimeSeconds() + TurnDelay;
		Rotation.Velocity = 0.f;

		System::ClearTimer(this, n"ClearPlayerMarker");
		System::ClearTimer(this, n"ClearSettings");
		ApplySettingsTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		System::SetTimer(this, n"ClearPlayerMarker", 1.f, false);

		if (ApplySettingsTime != 0.f)
		{
			float RemainingSettingsTime = ApplySettingsTime + SettingsDuration - Time::GetRealTimeSeconds(); 
			if (RemainingSettingsTime < 0.01f)
				ClearSettings();
			else
				System::SetTimer(this, n"ClearSettings", RemainingSettingsTime, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ClearPlayerMarker()
	{
		StopForceEnablePlayerMarker(OtherPlayer, this);
		System::ClearTimer(this, n"ClearPlayerMarker");
	}

	UFUNCTION(NotBlueprintCallable)
	void ClearSettings()
	{
		ApplySettingsTime = 0.f;
		Player.ClearCameraSettingsByInstigator(this, SettingsBlendOutDuration);
		System::ClearTimer(this, n"ClearSettings");
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ClearPlayerMarker();
		ClearSettings();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (User.IsAiming() || SceneView::IsFullScreen())
		{
			Player.ClearCameraSettingsByInstigator(this, 1.f);
			ApplySettingsTime = 0.f;
			Rotation.Velocity = 0.f;
			return;
		}

		if (Time::GetRealTimeSeconds() >= TurnCameraTime)
		{
			Rotation.Value = User.GetDesiredRotation(); // This value is expected to be changed elsewhere
			FRotator ToOther = (GetOtherPlayerIndicatorLocation() - Player.PlayerViewLocation).Rotation();
			FRotator FaceOtherRot = Rotation.AccelerateTo(ToOther, TurnDuration, DeltaTime / FMath::Max(0.01f, Owner.ActorTimeDilation));
			User.SetDesiredRotation(FaceOtherRot);
		}

		// Apply settings when other player is approaching screen
		if (Player.ViewRotation.Vector().DotProduct((GetOtherPlayerIndicatorLocation() - Player.ViewLocation).GetSafeNormal()) > 0.75f)
		{
			if (ApplySettingsTime == 0.f)
				ApplySettingsTime = Time::GetRealTimeSeconds();
			Player.ApplyCameraSettings(User.FindOtherPlayerAdditiveSettings, CameraBlend::Additive(SettingsBlendInDuration), this, EHazeCameraPriority::Medium);
		}
	}

	FVector GetOtherPlayerIndicatorLocation() const
	{
		if (Settings.bOverridePlayerLocation)
			return Settings.OverrideLocation;

		return OtherPlayer.FocusLocation;
	}
}