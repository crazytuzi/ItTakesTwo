import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;

UCLASS(Deprecated)
class UMusicalFlyingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"MusicalFlyingCamera");

	default CapabilityDebugCategory = n"Movement Flying";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUser;
	UHazeCameraComponent Camera;
	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;
	UMusicalFlyingSettings Settings;

	float NewIdealDistance = 0.0f;


	FHazeAcceleratedRotator AcceleratedTargetRotation;
	FHazeAcceleratedVector2D AcceleratedInput;

	float CurrentYawOffset = 0;

	FRotator CurrentRotation;

	FVector TargetOffset;

	FHazeAcceleratedRotator ChaseRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		Camera = UHazeCameraComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.FlyingStartupTime > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.ExitVolumeBehavior == EMusicalFlyingExitVolumeBehavior::HalfLoop)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(FlyingComp.ExitVolumeBehavior == EMusicalFlyingExitVolumeBehavior::HalfLoop)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		NewIdealDistance = FlyingComp.FlyingCamSettings.SpringArmSettings.IdealDistance;
		AcceleratedTargetRotation.Value = CameraUser.WorldToLocalRotation(Player.Mesh.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearIdealDistanceByInstigator(this);
		Player.ClearCameraOffsetByInstigator(this);
	}

	bool IsInputPressed() const
	{
		return GetAttributeVector2D(AttributeVectorNames::MovementRaw).SizeSquared() > 0.1f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FRotator TargetRotation = CameraUser.WorldToLocalRotation(Player.Mesh.WorldRotation);
		
		const float YawOffset = 5;
		const float YawOffsetSpeed = !IsInputPressed() ? 0.5f : 20.0f;
		const float TargetYawOffset = YawOffset * Input.Y;
		CurrentYawOffset = FMath::FInterpTo(CurrentYawOffset, TargetYawOffset, DeltaTime, YawOffsetSpeed);
		//PrintToScreen("CurrentYawOffset " + CurrentYawOffset);

		TargetRotation.Yaw += CurrentYawOffset;

		float TimeDilation = Owner.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.0f) ? DeltaTime / TimeDilation : 1.0f;

		//AcceleratedTargetRotation.AccelerateTo(TargetRotation, 2.0f, RealTimeDeltaSeconds);

		const float VelocitySize = MoveComp.Velocity.Size();
		const float SpeedScalar = VelocitySize / Settings.FlyingSpeed;

		const float IdealDistanceMax = 0;
		const float IdealDistanceMin = 0;

		NewIdealDistance = FMath::FInterpTo(NewIdealDistance, FlyingComp.FlyingCamSettings.SpringArmSettings.IdealDistance * SpeedScalar, DeltaTime, 10.0f);
		Player.ApplyIdealDistance(NewIdealDistance, FHazeCameraBlendSettings(1.0f), this, EHazeCameraPriority::High);
		//PrintToScreen("NewIdealDistance " + NewIdealDistance);

		const float OffsetLength = 500.0f;
		const FVector OffsetMax(0, OffsetLength * Input.Y, (OffsetLength * 0.5f) * -Input.X);
		const float Alpha = FMath::Clamp((TargetOffset.SizeSquared()) / FMath::Square(OffsetLength), 0.1f, 1.0f );

		const float Exp = 1.1f;
		
		TargetOffset = FMath::EaseInOut(TargetOffset, OffsetMax, Alpha, Exp);

		TargetOffset.GetClampedToMaxSize(OffsetLength);
		//PrintToScreen("TargetOffset " + TargetOffset);
		//PrintToScreen("Alpha " + Alpha);

		Player.ApplyCameraOffset(TargetOffset, FHazeCameraBlendSettings(1.0f), this, EHazeCameraPriority::Script);

		FRotator DesiredRotation = CameraUser.WorldToLocalRotation(CameraUser.GetDesiredRotation());
		AcceleratedTargetRotation.Value = DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(TargetRotation, 0.8f, DeltaTime);

		
		
		//CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
		FRotator DeltaRot = (AcceleratedTargetRotation.Value - DesiredRotation).GetNormalized();
		CameraUser.AddDesiredRotation(DeltaRot);
	}
}
