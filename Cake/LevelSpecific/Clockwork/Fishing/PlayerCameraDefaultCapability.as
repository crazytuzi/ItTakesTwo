import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;

class UPlayerCameraDefaultCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"PlayerCameraDefaultCapability");
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default CapabilityDebugCategory = n"GamePlay";	
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;

	UCameraComponent CameraComp;

	UCameraUserComponent CameraUser;

	UPlayerFishingComponent PlayerComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	FVector CamRightVector;

	FHazeAcceleratedFloat FinalMultiplier;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraComp = UCameraComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		PlayerComp = UPlayerFishingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PlayerComp.bHaveActivatedCam && PlayerComp.FishingState == EFishingState::Default)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).IsNearlyZero() && PlayerComp.FishingState == EFishingState::Default)
			return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero() && GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).IsNearlyZero())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (PlayerComp.FishingState != EFishingState::Default)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 2.2f;
		Player.ApplyCameraSettings(PlayerComp.SpringArmSettingsDefault, BlendSettings, this); 
		PlayerComp.bHaveActivatedCam = true;
		AcceleratedTargetRotation.SnapTo(CameraUser.DesiredRotation);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AcceleratedTargetRotation.SnapTo(FRotator(0.f));
		Player.ClearCurrentPointOfInterest();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5f);
		PlayerComp.bHaveActivatedCam = false;
		Player.ClearCurrentPointOfInterest();
    }

	UFUNCTION(BlueprintOverride)	
	void TickActive(float DeltaTime)
	{	
		FVector LookOffset(0.f, 0.f, -20.f);
		FVector ForwardOffset = Player.ActorForwardVector * 350.f;
		FVector ZOffset(0.f, 0.f, -150);
		// FVector LookDirection = (PlayerComp.FishballLoc - GetCameraLookPosition()) + ZOffset + ForwardOffset;

		// LookDirection.Z *= 0.5f;

		// FRotator CameraMakeRot = FRotator::MakeFromXZ(LookDirection + LookOffset, FVector::UpVector);
		// AcceleratedTargetRotation.AccelerateTo(CameraMakeRot, 0.68f, DeltaTime);
		// CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;	
		FVector LookLocation = PlayerComp.FishballLoc + ZOffset + ForwardOffset;

		FHazePointOfInterest POI;
		POI.Blend = 1.5f;
		POI.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		POI.FocusTarget.WorldOffset = LookLocation;
		
		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);
	}	

	FVector GetCameraLookPosition()
	{
		FVector PlayerCameraPosition = Player.ViewLocation;
		return PlayerCameraPosition;
	}
}