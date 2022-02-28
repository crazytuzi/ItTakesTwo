import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceSkatingCameraComponent CameraComp;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		CameraComp = UIceSkatingCameraComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ApplyCameraSettings(CameraComp.Settings, FHazeCameraBlendSettings(2.f), this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams ActivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}