import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexDashCameraCapability;

class USwimmingVortexCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Underwater);
	default CapabilityTags.Add(SwimmingTags::Vortex);
	default CapabilityTags.Add(SwimmingTags::Camera);
	default CapabilityTags.Add(CameraTags::CustomControl);

	default CapabilityDebugCategory = n"Movement Swimming";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	USnowGlobeSwimmingComponent SwimComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;
	FSwimmingVortexSettings VortexSettings;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		CameraUser = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SwimComp == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if (!SwimComp.bVortexActive)
			return EHazeNetworkActivation::DontActivate;

		if (Owner.IsAnyCapabilityActive(USwimmingVortexDashCameraCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwimComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (!SwimComp.bVortexActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Owner.IsAnyCapabilityActive(USwimmingVortexDashCameraCapability::StaticClass()))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);

		if (SwimComp.VortexCameraSettings != nullptr)
			Player.ApplyCameraSettings(SwimComp.VortexCameraSettings, FHazeCameraBlendSettings(2.f), this, EHazeCameraPriority::Medium);			

		Player.BlockCapabilities(n"CameraControl", this);			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (SwimComp.VortexCameraSettings != nullptr)
			Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(n"CameraControl", this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{		
		FVector TargetDirection = Owner.ActorForwardVector;

		FRotator CameraRotation = Math::MakeRotFromX(TargetDirection);
		CameraRotation.Roll = 0.f;
		CameraRotation.Pitch -= VortexSettings.ChaseCameraPitch;

		AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(CameraRotation, VortexSettings.ChaseCameraAcceleration, DeltaTime);
		CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}
}