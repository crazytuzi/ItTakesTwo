import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Components.CameraUserComponent;

class UPlayerCameraEngagedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"PlayerCameraEngagedCapability");

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

	float NetTime;
	float NetRate = 0.35f;
	FRotator NetRotationTarget;
	FHazeAcceleratedRotator NetAccelRotator;

	FHazeAcceleratedFloat AccelZOffset;

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
		if (PlayerComp.FishingState == EFishingState::WindingUp 
		|| PlayerComp.FishingState == EFishingState::Casting 
		|| PlayerComp.FishingState == EFishingState::Catching)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::WindingUp 
		&& PlayerComp.FishingState != EFishingState::Casting 
		&& PlayerComp.FishingState != EFishingState::Catching)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.2f;
		
		if (Player == Game::GetMay())
			Player.ApplyCameraSettings(PlayerComp.SpringArmSettingsEngagedMay, BlendSettings, this); 
		else 
			Player.ApplyCameraSettings(PlayerComp.SpringArmSettingsEngagedCody, BlendSettings, this); 
	
		Player.BlockCameraSyncronization(this);
		CameraUser.RegisterDesiredRotationReplication(this);

		AccelZOffset.SnapTo(-150.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 1.2f);
		Player.UnblockCameraSyncronization(this);
		CameraUser.UnregisterDesiredRotationReplication(this);
		Player.ClearCurrentPointOfInterest();
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

		if (PlayerComp.FishingState != EFishingState::WindingUp)
			AccelZOffset.AccelerateTo(200.f, 3.f, DeltaTime);

		FVector ZOffset(0.f, 0.f, AccelZOffset.Value);

		FVector LookLocation = PlayerComp.FishballLoc + ZOffset + ForwardOffset;

		FHazePointOfInterest POI;
		POI.Blend = 2.75f;
		POI.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		POI.FocusTarget.WorldOffset = LookLocation;
		
		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);
	}

	UFUNCTION(NetFunction)
	void NetSetRotationTarget(FRotator Target)
	{
		NetRotationTarget = Target;
	}

	FVector GetCameraLookPosition()
	{
		FVector PlayerCameraPosition = Player.ViewLocation;
		return PlayerCameraPosition;
	}
}