import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.Weapons.Sap.SapWeaponCrosshairWidget;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantTags;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Tutorial.TutorialStatics;

class UTurretPlantPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ATurretPlant TurretPlant;
	UCameraUserComponent CameraUser;
	AHazePlayerCharacter Player;
	UHazeSmoothSyncFloatComponent SyncedZoom;
	UControllablePlantsComponent PlantsComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantsComp = UControllablePlantsComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SyncedZoom = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"TurretPlantSyncedZoom");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{			
		if (PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlantsComp.CurrentPlant.IsA(ATurretPlant::StaticClass()))
			return EHazeNetworkActivation::DontActivate;
        	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TurretPlant = Cast<ATurretPlant>(PlantsComp.CurrentPlant);

		Player.ShowCancelPrompt(this);

		CameraUser.SetAiming(this);
		SyncedZoom.Value = TurretPlant.SpringArmSettings.CameraSettings.FOV;

		FTutorialPrompt ZoomPrompt;
		ZoomPrompt.Action = ActionNames::WeaponAim;
		ZoomPrompt.Text = TurretPlant.AimPrompt;
		ZoomPrompt.MaximumDuration = 10.f;
		ZoomPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, ZoomPrompt, this);

		FTutorialPrompt ShootPrompt;
		ShootPrompt.Action = ActionNames::WeaponFire;
		ShootPrompt.Text = TurretPlant.FirePrompt;
		ShootPrompt.MaximumDuration = 10.f;
		ShootPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, ShootPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		Player.RemoveCancelPromptByInstigator(this);
		CameraUser.ClearAiming(this);
		Player.ClearCameraSettingsByInstigator(this, 0.5f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			const float ZoomAmount = TurretPlant.bIsExiting ? 0.0f : GetAttributeValue(AttributeNames::WeaponAimAxis);
			const float FireRate = GetAttributeValue(AttributeNames::WeaponFireAxis);

			FVector2D PlayerInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
			TurretPlant.UpdatePlayerInput(PlayerInput, FireRate, ZoomAmount, IsActioning(ActionNames::WeaponReload), IsActioning(ActionNames::Cancel));

			const float FOV = TurretPlant.SpringArmSettings.CameraSettings.FOV;
			const float TargetFOV = FOV * (1.0f - ( (TurretPlant.ZoomMultiplier - 1.0f) * ZoomAmount));
			const float NewSensitivityFactor = 1.0f - ((TurretPlant.AimSensitivityFactor - 1.0f) * ZoomAmount);
			FHazeCameraBlendSettings CameraBlend;
			CameraBlend.BlendTime = 0.5f;
			Player.ApplyFieldOfView(TargetFOV, CameraBlend, this, EHazeCameraPriority::High);
			FHazeCameraSettings CameraSettings;
			CameraSettings.bUseSensitivityFactor = true;
			CameraSettings.SensitivityFactor = NewSensitivityFactor;
			CameraSettings.bUseSnapOnTeleport = true;
			CameraSettings.bSnapOnTeleport = false;
			Player.ApplySpecificCameraSettings(CameraSettings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), CameraBlend, this, EHazeCameraPriority::Medium);
			SyncedZoom.Value = TargetFOV;
			TurretPlant.ZoomFraction = CalculateZoomFraction(TargetFOV);
		}
		else
		{
			FHazeCameraBlendSettings CameraBlend;
			CameraBlend.BlendTime = 0.5f;
			Player.ApplyFieldOfView(SyncedZoom.Value, CameraBlend, this, EHazeCameraPriority::High);
			TurretPlant.ZoomFraction = CalculateZoomFraction(SyncedZoom.Value);
		}
	}

	private float CalculateZoomFraction(float TargetFOV)
	{
		const float FOV = TurretPlant.SpringArmSettings.CameraSettings.FOV;
		const float FOVDiff = FOV * (1.0f - ( (TurretPlant.ZoomMultiplier - 1.0f) * 1.0f));
		const float FOVMax = FOV - FOVDiff;
		const float FOVCurrent = TargetFOV - FOVDiff;
		const float FOVFraction = 1.0f - (FOVCurrent / FOVMax);
		return FOVFraction;
	}
}
