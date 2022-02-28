import Vino.LevelSpecific.Snowglobe.SnowGlobeMagnetSplineComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class ASnowGlobeTownPulka : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent ScriptRoot;

	UPROPERTY(DefaultComponent)
	USnowGlobeMagnetSplineComponent ScriptSplineComp;
	default ScriptSplineComp.TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;

	FHazeAcceleratedQuat ArmQuat;
	FHazeAcceleratedFloat Pitch;
	FHazeAcceleratedFloat Yaw;
	FHazeAcceleratedFloat Distance;
	default Distance.Value = 1000.f;

	FHazeAcceleratedVector RootPosition;
	FHazeAcceleratedQuat RootQuat;

	FHazeAcceleratedFloat Fov;
	FHazeAcceleratedFloat Shimmer;

	const float UpOffset = 150.f;

	const float RootAccelTime = 0.4f;
	const float SpeedAccelTime = 0.8f;
	const float YawAccelTime = 4.5f;

	const float SlowDistance = 800.f;
	const float FastDistance = 400.f;
	const float SlowArm = FMath::DegreesToRadians(20.f);
	const float FastArm = FMath::DegreesToRadians(5.f);

	const float SlowFov = 60.f;
	const float FastFov = 90.f;
	const float MaxShimmer = 1.f;

	float CameraDirection = 1.f;
	AHazePlayerCharacter CurrentPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddTickPrerequisiteComponent(ScriptSplineComp);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateCamera(AHazePlayerCharacter Player)
	{
		CurrentPlayer = Player;
		Player.ActivateCamera(Camera, CameraBlend::Normal(), this);
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateCamera(AHazePlayerCharacter Player)
	{
		CurrentPlayer.ClearCameraSettingsByInstigator(this);
		CurrentPlayer.DeactivateCameraByInstigator(this);
		CurrentPlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ScriptSplineComp.Distance.Value > 11100.f)
			CameraDirection = -1.f;
		if (ScriptSplineComp.Distance.Value < 4200.f)
			CameraDirection = 1.f;

		Yaw.AccelerateTo(90.f - 90.f * CameraDirection, YawAccelTime, DeltaTime);
		ApplySpeedBlending(DeltaTime);

		RootPosition.AccelerateTo(ScriptSplineComp.WorldLocation, RootAccelTime, DeltaTime);
		RootQuat.AccelerateTo(ScriptSplineComp.WorldRotation.Quaternion(), RootAccelTime, DeltaTime);

		FQuat YawQuat = FQuat(FVector::UpVector, FMath::DegreesToRadians(Yaw.Value));
		FQuat PitchQuat = FQuat(FVector::RightVector, FMath::DegreesToRadians(Pitch.Value));
		FTransform RootTransform = FTransform(RootQuat.Value, RootPosition.Value);
		FTransform OffsetTransform = FTransform(FVector(-Distance.Value, 0.f, UpOffset));

		//FTransform NewCamera = FTransform() * PitchQuat.Value * YawQuat.Value * PitchQuat.Value.Inverse() * OffsetTransform * PitchQuat.Value * ScriptSplineComp.RelativeTransform;
		FTransform NewCamera = FTransform() * PitchQuat * ArmQuat.Value.Inverse() * OffsetTransform * ArmQuat.Value * YawQuat * RootTransform;
		Camera.WorldTransform = NewCamera;

		if (CurrentPlayer != nullptr)
		{
			CurrentPlayer.ApplyFieldOfView(Fov.Value, CameraBlend::Normal(), this);
			SpeedEffect::RequestSpeedEffect(CurrentPlayer, FSpeedEffectRequest(Shimmer.Value, this, true));
		}
	}

	void ApplySpeedBlending(float DeltaTime)
	{
		float SpeedPercent = Math::Saturate((ScriptSplineComp.Distance.Velocity * CameraDirection) / 3000.f);

		float TargetDistance = FMath::Lerp(SlowDistance, FastDistance, SpeedPercent);
		FQuat TargetArm = FQuat(FVector::RightVector, FMath::Lerp(SlowArm, FastArm, SpeedPercent));
		float TargetFov = FMath::Lerp(SlowFov, FastFov, SpeedPercent);
		float TargetShimmer = MaxShimmer * SpeedPercent;

		Distance.AccelerateTo(TargetDistance, SpeedAccelTime, DeltaTime);
		ArmQuat.AccelerateTo(TargetArm, SpeedAccelTime, DeltaTime);
		Fov.AccelerateTo(TargetFov, SpeedAccelTime, DeltaTime);
		Shimmer.AccelerateTo(TargetShimmer, SpeedAccelTime, DeltaTime);
	}
}