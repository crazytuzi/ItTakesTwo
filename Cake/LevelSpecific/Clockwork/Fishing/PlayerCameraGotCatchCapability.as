import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Components.CameraUserComponent;

class UPlayerCameraGotCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"PlayerCameraGotCatchCapability");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UPlayerFishingComponent PlayerComp;

	UCameraComponent CameraComp;

	UCameraUserComponent CameraUser;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	FVector CamRightVector;

	FHazeAcceleratedFloat FinalMultiplier;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
		CameraComp = UCameraComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.FishingState == EFishingState::Reeling 
		|| PlayerComp.FishingState == EFishingState::Hauling 
		|| PlayerComp.FishingState == EFishingState::HoldingCatch)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::Reeling 
		&& PlayerComp.FishingState != EFishingState::Hauling 
		&& PlayerComp.FishingState != EFishingState::HoldingCatch)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (PlayerComp.FishingState == EFishingState::ThrowingCatch)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.2f;
		Player.BlockCameraSyncronization(this);

		if (Player == Game::GetMay())
			Player.ApplyCameraSettings(PlayerComp.SpringArmSettingsGotCatchMay, BlendSettings, this); 
		else 
			Player.ApplyCameraSettings(PlayerComp.SpringArmSettingsGotCatchCody, BlendSettings, this); 

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 1.2f);
		Player.ClearCurrentPointOfInterest();
		Player.UnblockCameraSyncronization(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.2f);
		Player.ClearCurrentPointOfInterest();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector LookOffset(0.f, 0.f, -20.f);
		FVector ForwardOffset = Player.ActorForwardVector * 350.f;

		float ZDiff = PlayerComp.FishballLoc.Z - Player.ActorLocation.Z;
		float ZTarget = (-ZDiff - 150.f);
		ZTarget *= 0.75f;
		FVector ZOffset(0.f, 0.f, ZTarget);

		FVector LookDirection = (PlayerComp.FishballLoc - Player.ViewLocation) + ZOffset + ForwardOffset;

		FVector LookLocation = PlayerComp.FishballLoc + ZOffset + ForwardOffset;

		FHazePointOfInterest POI;
		POI.Blend = 1.5f;
		POI.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		POI.FocusTarget.WorldOffset = LookLocation;
		
		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);
	}
}