import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexDashCapability;

class USwimmingVortexDashCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
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

		if (!Owner.IsAnyCapabilityActive(USwimmingVortexDashCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwimComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!Owner.IsAnyCapabilityActive(USwimmingVortexDashCapability::StaticClass()))
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
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(n"CameraControl", this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		//DebugDrawLineDelta(TargetDirection);

		UpdateDesiredRotation(DeltaTime);
		UpdatePivotOffsetBasedOnTargetDirection(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FRotator CameraRotation = Math::MakeRotFromX(TargetDirection);
		CameraRotation.Roll = 0.f;
		CameraRotation.Pitch *= VortexSettings.DashCameraPitchScale;

		AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(CameraRotation, VortexSettings.DashCameraAcceleration, DeltaTime);
		CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}

	void UpdatePivotOffsetBasedOnTargetDirection(float DeltaTime)
	{	
		FVector UpVector = Owner.ActorTransform.TransformVector(VortexSettings.DashDirection).CrossProduct(Owner.ActorRightVector);
		UpVector = MoveComp.WorldUp;
		//DebugDrawLineDelta(UpVector * 250.f);

		float PitchScale = -TargetDirection.GetSafeNormal().DotProduct(UpVector.GetSafeNormal());
		PitchScale = FMath::Clamp(PitchScale, 0.f, 1.f);
		PrintToScreenScaled("" + PitchScale, Scale = 2.f);

		Player.ApplyCameraSettings(SwimComp.VortexDashCameraSettings, CameraBlend::ManualFraction(PitchScale, 0.8f), this, EHazeCameraPriority::High);

		// 		FVector PivotOffset = DefaultPivotOffset + (FVector::UpVector * PivotOffsetScale * 600.f);
		// FVector RelativePivotOffset = Owner.GetActorTransform().InverseTransformVector(MoveComp.DownHit.Normal);
		// Player.ApplyPivotOffset(PivotOffset, FHazeCameraBlendSettings(1.5f), this);
	}

	FVector GetTargetDirection() property
	{
		if (!MoveComp.Velocity.IsNearlyZero(20.f) && MoveComp.Velocity.DotProduct(Owner.ActorForwardVector) > 0.f)
		{
			if (MoveComp.Velocity.DotProduct(MoveComp.WorldUp) > 0.f)
				return MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			else
				return MoveComp.Velocity;
		}

		return Owner.ActorForwardVector;
	}
}