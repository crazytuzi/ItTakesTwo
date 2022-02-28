import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Components.CameraSpringArmComponent;

class USwingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingCamera");

	default CapabilityDebugCategory = n"Movement Swinging";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USwingingComponent SwingingComponent;
	UCameraUserComponent CameraUser;
	UCameraSpringArmComponent SpringArmComp;

	const float BlendInTime = 1.5f;
	const float BlendOutTime = 3.5f;
	const float PivotOffsetDistanceUpRope = 175.f;
	const float CameraOffsetMaxOffset = -200.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Player);
		SpringArmComp = UCameraSpringArmComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SwingingComponent.ActiveSwingPoint == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!SwingingComponent.ActiveSwingPoint.CameraSettings.bApplySwingCameraSettings)
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwingingComponent.ActiveSwingPoint == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		// If active swing point changes to one that doesn't want to apply
		if (!SwingingComponent.ActiveSwingPoint.CameraSettings.bApplySwingCameraSettings)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (SwingingComponent.ActiveSwingPoint.CameraSettingsOverride == nullptr)
			Player.ApplyCameraSettings(SwingingComponent.DefaultCameraSettings, FHazeCameraBlendSettings(BlendInTime), this);
		else
			Player.ApplyCameraSettings(SwingingComponent.ActiveSwingPoint.CameraSettingsOverride, FHazeCameraBlendSettings(BlendInTime), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, BlendOutTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Update the pivot offset to somewhere along the rope
		FVector PivotOffsetWorld = SwingingComponent.PlayerLocation + (SwingingComponent.PlayerToSwingPoint.GetSafeNormal() * PivotOffsetDistanceUpRope);
		FVector PivotOffset = PivotOffsetWorld - SwingingComponent.PlayerLocation;		
		SpringArmComp.SetWorldPivotOffset(PivotOffset, 200.f);

		// Update the camera offset to lower the camera based on swing angle
		const float CameraOffsetZ = 0.f + (SwingingComponent.GetSwingAnglePercentage() * CameraOffsetMaxOffset);
		FVector CameraOffset = FVector(0.f, 0.f, CameraOffsetZ);
		Player.ApplyCameraOffset(CameraOffset, FHazeCameraBlendSettings(BlendInTime), this);

		if (IsDebugActive())
		{
			System::DrawDebugSphere(PivotOffsetWorld, 25.f, 10.f);
			PrintToScreenScaled("SwingAnglePercentage: " + SwingingComponent.GetSwingAnglePercentage());
		}
	}
}