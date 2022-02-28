import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Vino.Camera.Components.CameraUserComponent;

class UFlyingMachineGunnerAimZoomCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Gunner);
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 50;
	default CapabilityDebugCategory = FlyingMachineCategory::Gunner;

	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUser;
	UFlyingMachineGunnerComponent Gunner;

	AFlyingMachineTurret Turret;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Gunner = UFlyingMachineGunnerComponent::GetOrCreate(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Gunner.CurrentTurret == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Gunner.CurrentTurret == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Turret = Gunner.CurrentTurret;

		// Blending
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 0.5f;

		// Settings
		Player.ApplyCameraSettings(
			Turret.ZoomedCameraSettings,
			BlendSettings,
			this,
			EHazeCameraPriority::Medium
		);

		CameraUser.SetAiming(this);

		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Weapons_Guns_FlakTurret_IsZooming", 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
		CameraUser.ClearAiming(this);

		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Weapons_Guns_FlakTurret_IsZooming", 0.f);
	}
}