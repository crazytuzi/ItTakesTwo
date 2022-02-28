import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonProjectile;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonBeam;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonMovementSpline;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraDetacherComponent;

class ACastleCannon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbVisualizeComponent(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraDetacherComponent CameraDetacherComp;

	UPROPERTY(DefaultComponent, Attach = CameraDetacherComp)
	UCameraSpringArmComponent SpringArmComp;

	UPROPERTY(DefaultComponent, Attach = SpringArmComp)
	UHazeCameraComponent Camera;
	default Camera.Settings.FOV = 50.f;
	default Camera.Settings.bUseFOV = true;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent DistanceAlongSplineSyncComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent YawPivot;

	UPROPERTY(DefaultComponent, Attach = YawPivot)
	USceneComponent PitchPivot;

	UPROPERTY(DefaultComponent, Attach = PitchPivot)
	USceneComponent ShooterAttach;

	UPROPERTY(DefaultComponent, Attach = PitchPivot)
	USceneComponent Muzzle;

	UPROPERTY()
	TSubclassOf<ACastleCannonProjectile> ProjectileType;

	UPROPERTY()
	TSubclassOf<ACastleCannonBeam> BeamType;
	ACastleCannonBeam CannonBeam;

	UPROPERTY()
	ACastleCannonMovementSpline CannonSpline;
	UPROPERTY()
	float DistanceAlongSpline;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettings;

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{		
		SnapCannonToSpline();	
	}

	void SnapCannonToSpline()
	{
		if (CannonSpline == nullptr)
			return;

		DistanceAlongSpline = CannonSpline.Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);

		FVector CannonLocation = GetLocationAtDistanceAlongSpline(DistanceAlongSpline);
		FRotator CannonRotation = GetRotationAtDistanceAlongSpline(DistanceAlongSpline);

		SetActorLocation(CannonLocation);
		SetActorRotation(CannonRotation);
	}

	FVector GetLocationAtDistanceAlongSpline(float DistanceAlongSpline)
	{
		FVector WorldLocation = CannonSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		return WorldLocation;
	}
	FRotator GetRotationAtDistanceAlongSpline(float DistanceAlongSpline)
	{
		FVector TangentAtDistance = CannonSpline.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector TangentRightVector = TangentAtDistance.GetSafeNormal().CrossProduct(FVector::UpVector).GetSafeNormal();
		FRotator TangentRotation = Math::MakeRotFromX(TangentRightVector);

		FRotator WorldRotation = FRotator(ActorRotation.Pitch, TangentRotation.Yaw, 0);

		return WorldRotation;
	}

	void MoveCannonToDistanceAlongSpline()
	{
		FVector CannonLocation = GetLocationAtDistanceAlongSpline(DistanceAlongSplineSyncComp.Value);
		FRotator CannonRotation = GetRotationAtDistanceAlongSpline(DistanceAlongSplineSyncComp.Value);

		SetActorLocation(CannonLocation);
		SetActorRotation(CannonRotation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetCody());

		if (BeamType.IsValid())
		{
			CannonBeam = Cast<ACastleCannonBeam>(SpawnActor(BeamType, Muzzle.WorldLocation, Muzzle.WorldRotation));
			CannonBeam.AttachToComponent(Muzzle);
		}
	}

	UFUNCTION(BlueprintEvent)
	void ShootCannon()
	{
		ACastleCannonProjectile Projectile;
		Projectile = Cast<ACastleCannonProjectile>(SpawnActor(ProjectileType, Muzzle.WorldLocation, Muzzle.WorldRotation));

		Projectile.Owner = this;
		Projectile.bActive = true;
	}

	UFUNCTION(BlueprintEvent)
	void StartBeam()
	{
		if (CannonBeam == nullptr)
			return;

		CannonBeam.ActivateBeam();
	}

	UFUNCTION(BlueprintEvent)
	void StopBeam()
	{
		if (CannonBeam == nullptr)
			return;

		CannonBeam.DeactivateBeam();
	}
}