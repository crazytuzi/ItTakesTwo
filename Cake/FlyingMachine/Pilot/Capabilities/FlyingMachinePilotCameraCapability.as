import Cake.FlyingMachine.Pilot.FlyingMachinePilotComponent;
import Cake.FlyingMachine.FlyingMachineNames;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UFlyingMachinePilotCameraCapability : UHazeCapability
{
	// Not gameplayation as we don't want to block this during cutscenes.
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Camera);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default CapabilityDebugCategory = FlyingMachineCategory::Machine;
	
	AHazePlayerCharacter Player;
	UFlyingMachinePilotComponent PilotComp;

	AFlyingMachine Machine;
	bool bWasInMeleeFight = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PilotComp = UFlyingMachinePilotComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PilotComp.CurrentMachine == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PilotComp.CurrentMachine == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Machine = PilotComp.CurrentMachine;

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		Player.ApplyCameraSettings(Machine.PilotCamera.SettingsAsset, Blend, this, EHazeCameraPriority::Low);
		Player.ActivateCamera(Machine.PilotCamera, Blend, this, EHazeCameraPriority::Low);

		bWasInMeleeFight = Machine.bIsInMeleeFight;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DeactivateCameraByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!Machine.bIsInMeleeFight)
		{
			// Bring the camera in
			float ExtraDistance = -900.f * Machine.SpeedPercent;

			FHazeCameraSpringArmSettings SpringSettings;
			SpringSettings.bUseIdealDistance = true;
			SpringSettings.IdealDistance = ExtraDistance;
			SpringSettings.bUseMinDistance = true;
			SpringSettings.MinDistance = ExtraDistance;

			Player.ApplyCameraSpringArmSettings(SpringSettings, CameraBlend::Additive(2.f), this, EHazeCameraPriority::High);
		}
		else
		{
			// We used to not be in the fight so we need to clear the settings we have made
			if(!bWasInMeleeFight)
				Player.ClearCameraSettingsByInstigator(this);	
		}
		bWasInMeleeFight = Machine.bIsInMeleeFight;

		// Field of view (apply after any potential clearing due to no longer being in melee)
		float ExtraFov = 30.f * Machine.SpeedPercent;
		Player.ApplyFieldOfView(ExtraFov, CameraBlend::Additive(2.f), this, EHazeCameraPriority::High);

		// Make speed shimmer
		FSpeedEffectRequest SpeedEffect;
		SpeedEffect.Instigator = this;
		SpeedEffect.Value = Machine.SpeedPercent * 0.5f;
		SpeedEffect.bSnap = false;
		SpeedEffect::RequestSpeedEffect(Player, SpeedEffect);
	}
}