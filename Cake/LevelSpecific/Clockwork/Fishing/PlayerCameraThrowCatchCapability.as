import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Clockwork.Fishing.RodBase;
import Vino.Camera.Components.CameraUserComponent;

class UPlayerCameraThrowCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"PlayerCameraThrowCatchCapability");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCameraUserComponent UserComp;
	UPlayerFishingComponent PlayerComp;
	ARodBase RodBase;

	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.FishingState == EFishingState::ThrowingCatch)	
	        return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::ThrowingCatch)	
	        return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RodBase = Cast<ARodBase>(PlayerComp.RodBase);
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.4f;
		Player.ApplyCameraSettings(PlayerComp.SpringArmSettingsThrowCatch, BlendSettings, this); 
		PlayerComp.CameraThrowCatch.ActivateCamera(Player, BlendSettings, this);
		AccelRot.SnapTo(UserComp.DesiredRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 1.2f);
		PlayerComp.CameraThrowCatch.DeactivateCamera(Player, 1.2f);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ClearCurrentPointOfInterest();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (RodBase.CurrentCatch == nullptr)
			return;

		FVector ForwardDirection = (RodBase.CurrentCatch.ActorLocation + FVector(0.f, 0.f, -50.f)) - PlayerComp.CameraThrowCatch.ActorLocation; 
		FRotator CameraRotation = FRotator::MakeFromX(ForwardDirection);
		AccelRot.AccelerateTo(CameraRotation, 0.8f, DeltaTime);
		PlayerComp.CameraThrowCatch.SetActorRotation(AccelRot.Value);
	}
}