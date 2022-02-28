import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

class UCymbalPlayerLaserReflectCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UCymbalComponent CymbalComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CymbalComp = UCymbalComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!CymbalComp.bShieldActive)
			return EHazeNetworkActivation::DontActivate;

		if(CymbalComp.ShieldImpactingActors.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraSettings SensitivitySettings;
		SensitivitySettings.bUseSensitivityFactor = true;
		SensitivitySettings.SensitivityFactor = 0.3f;
		Player.ApplySpecificCameraSettings(SensitivitySettings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), CameraBlend::Normal(0.5f), this, EHazeCameraPriority::High);

		UMovementSettings MovementSettings = UMovementSettings::GetSettings(Owner);
		float OriginalMovementSpeed = MovementSettings.MoveSpeed;
		UMovementSettings::SetMoveSpeed(Owner, OriginalMovementSpeed * 0.4f, this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!CymbalComp.bShieldActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(CymbalComp.ShieldImpactingActors.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this);
	}
}
