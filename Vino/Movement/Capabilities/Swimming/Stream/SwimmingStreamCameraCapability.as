import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USwimmingStreamCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Underwater);
	default CapabilityTags.Add(SwimmingTags::Camera);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	USnowGlobeSwimmingComponent SwimComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;

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
		
		if (SwimComp.ActiveStream == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SwimComp.ActiveStream.StreamComponent.bBlockStreamCamera)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwimComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (SwimComp.ActiveStream == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SwimComp.ActiveStream.StreamComponent.bBlockStreamCamera)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);	

		if (SwimComp.StreamCameraSettings != nullptr)
			Player.ApplyCameraSettings(SwimComp.StreamCameraSettings, FHazeCameraBlendSettings(2.f), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 4.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdatePivotOffset(DeltaTime);
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{		
		float DistanceAlongSpline = SwimComp.ActiveStream.StreamComponent.GetDistanceAlongSplineAtWorldLocation(Player.ActorLocation);

		if (SwimComp.ActiveStream.StreamComponent.IsClosedLoop())
			DistanceAlongSpline = (DistanceAlongSpline + SwimmingSettings::Stream.StreamCameraPredictionDistance) % SwimComp.ActiveStream.StreamComponent.SplineLength;
		else
			DistanceAlongSpline = DistanceAlongSpline + SwimmingSettings::Stream.StreamCameraPredictionDistance;

		FVector Tangent = SwimComp.ActiveStream.StreamComponent.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		FVector TargetDirection = Tangent.GetSafeNormal();
		if (MoveComp.Velocity.DotProduct(Tangent.GetSafeNormal()) < 0.f)
			TargetDirection = MoveComp.Velocity;

		FRotator CameraRotation = Math::MakeRotFromX(TargetDirection);
		CameraRotation.Roll = 0.f;
		CameraRotation.Pitch -= 15.f;

		AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(CameraRotation, SwimmingSettings::Stream.StreamCameraAccelereationSpeed, DeltaTime);
		CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}

	void UpdatePivotOffset(float DeltaTime)
	{		
		float PlayerDistanceAlongSpline = SwimComp.ActiveStream.StreamComponent.GetDistanceAlongSplineAtWorldLocation(Player.ActorLocation);
		FVector SplineLocation = SwimComp.ActiveStream.StreamComponent.GetLocationAtDistanceAlongSpline(PlayerDistanceAlongSpline, ESplineCoordinateSpace::World);
	
		FVector PlayerToSplineLocation = SplineLocation - Player.ActorLocation;
		PlayerToSplineLocation *= 0.03f;
		FVector PivotOffset = Player.ActorTransform.InverseTransformVectorNoScale(PlayerToSplineLocation);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyPivotOffset(PivotOffset, Blend, this);
		Player.ApplyIdealDistance(600.f, Blend, this, EHazeCameraPriority::High);
	}
}