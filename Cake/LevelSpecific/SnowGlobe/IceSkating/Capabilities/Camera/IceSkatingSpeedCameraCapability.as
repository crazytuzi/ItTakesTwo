import Rice.Math.MathStatics;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UIceSkatingSpeedCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 53;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceSkatingCameraComponent CameraComp;
	UHazeMovementComponent MoveComp;

	FIceSkatingCameraSettings Settings; 
	FIceSkatingFastSettings FastSettings; 

	FHazeAcceleratedFloat ZoomAmount;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		CameraComp = UIceSkatingCameraComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
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
	void OnActivated(FCapabilityActivationParams Params)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Speed = MoveComp.Velocity.Size();
		float SpeedPercent = Math::GetPercentageBetweenClamped(FastSettings.MaxSpeed_Flat, FastSettings.MaxSpeed_Slope, Speed);

		ZoomAmount.AccelerateTo(SpeedPercent, Settings.SpeedZoomAccelerateDuration, DeltaTime);

		FHazeCameraSpringArmSettings UphillZoomSettings;
		UphillZoomSettings.bUseCameraOffsetOwnerSpace = true;
		UphillZoomSettings.CameraOffsetOwnerSpace = MoveComp.WorldUp * -100.f * ZoomAmount.Value;
		UphillZoomSettings.bUseIdealDistance = true;
		UphillZoomSettings.IdealDistance = -450.f * ZoomAmount.Value;

		FHazeCameraBlendSettings Blend = CameraBlend::Additive(0.5f);
		Player.ApplyCameraSpringArmSettings(UphillZoomSettings, Blend, this);
		Player.ApplyFieldOfView(40.f * ZoomAmount.Value, Blend, this);

		FSpeedEffectRequest SpeedEffect;
		SpeedEffect.Instigator = this;
		SpeedEffect.Value = ZoomAmount.Value;
		SpeedEffect.bSnap = false;
		SpeedEffect::RequestSpeedEffect(Player, SpeedEffect);
	}
}