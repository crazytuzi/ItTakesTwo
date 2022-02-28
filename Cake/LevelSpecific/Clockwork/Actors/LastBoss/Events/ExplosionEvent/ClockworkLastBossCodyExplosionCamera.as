import Vino.Camera.Actors.PivotCamera;
import Vino.Camera.Components.CameraSpringArmComponent;
class AClockworkLastBossCodyExplosionCamera : APivotCamera
{
	FCameraFocusSettings FocusSettings;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY()
	FRuntimeFloatCurve CameraOffsetByPitchCurve;
	default CameraOffsetByPitchCurve.ExternalCurve = Asset("/Game/Blueprints/LevelSpecific/Clockwork/Actors/LastBoss/CurveCodyExplosionCameraOffsetByPitch.CurveCodyExplosionCameraOffsetByPitch");

	UHazeCameraComponent CinematicCamera;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Game::GetCody().CurrentlyUsedCamera == nullptr)
			return;

		if (Game::GetCody().CurrentlyUsedCamera.Owner != this)
			return;
		
		Game::GetCody().ApplyFieldOfView(CinematicCamera.GetFOVFromFocalLength(CinematicCamera.CurrentFocalLength), CameraBlend::Normal(0.f), this);

		UCameraSpringArmComponent SpringComp = Cast<UCameraSpringArmComponent>(Game::GetCody().GetCurrentlyUsedCameraParentComponent(TSubclassOf<UHazeCameraParentComponent>(UCameraSpringArmComponent::StaticClass())));
		FVector CodySpringPivotLoc = SpringComp.PreviousPivotLocation;
		float Dist = (CodySpringPivotLoc - CinematicCamera.WorldLocation).Size();
		Game::GetCody().ApplyIdealDistance(Dist, CameraBlend::Normal(0.5f), this, EHazeCameraPriority::Script);

		FCameraFocusSettings FS;
		FS.ManualFocusDistance = Dist;
		Game::GetCody().CurrentlyUsedCamera.FocusSettings = FS;
		Game::GetCody().CurrentlyUsedCamera.CurrentAperture = 0.5f;

		FHazePointOfInterest Poi;
		Poi.InitializeAsInputAssist();
		Poi.FocusTarget.Actor = Game::GetMay();
		Poi.Blend.BlendTime = 5.f;
		Game::GetCody().ApplyPointOfInterest(Poi, this);
	}

	UFUNCTION()
	void SetExplosionCameraActive(AActor CameraFocusTarget)
	{
		AttachToActor(Game::GetCody(), NAME_None, EAttachmentRule::SnapToTarget);
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.f;
		SetActorTickEnabled(true);
		Game::GetCody().ActivateCamera(this.Camera, Blend, this);

		CinematicCamera = UHazeCameraComponent::Get(CameraFocusTarget);
		
		FHazePointOfInterest Poi;
		Poi.FocusTarget.Actor = Game::GetMay();
		Poi.Blend.BlendTime = 0.5f;
		Poi.Clamps.ClampPitchDown = 60.f;
		Poi.Clamps.ClampPitchUp = 60.f;
		Poi.Clamps.ClampYawLeft = 60.f;
		Poi.Clamps.ClampYawRight = 60.f;
		Game::GetCody().ApplyClampedPointOfInterest(Poi, this, EHazeCameraPriority::Script);	 

		FHazeCameraSpringArmSettings SpringSettings;
		SpringSettings.bUsePivotLagSpeed = true;
		SpringSettings.PivotLagSpeed = FVector::OneVector;
		SpringSettings.bUsePivotOffset = true;
		SpringSettings.PivotOffset = FVector(0.f, -50.f, 150.f);
		SpringSettings.bUseCameraOffset = true;
		SpringSettings.CameraOffset = FVector(-200.f, 100.f, 100.f);
		SpringSettings.bUseCameraOffsetOwnerSpace = true;
		SpringSettings.CameraOffsetOwnerSpace = FVector::ZeroVector;
		SpringSettings.bUseCameraOffsetByPitchCurve = true;
		SpringSettings.CameraOffsetByPitchCurve = CameraOffsetByPitchCurve;
		Game::GetCody().ApplyCameraSpringArmSettings(SpringSettings, CameraBlend::Normal(0.f), this, EHazeCameraPriority::Script);
	}

	UFUNCTION()
	void DeactivateExplosionCamera()
	{
		SetActorTickEnabled(false);
		Game::GetCody().DeactivateCameraByInstigator(this);
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Game::GetCody().ClearCameraSettingsByInstigator(this);
		Game::GetCody().ClearPointOfInterestByInstigator(this);
		Game::GetCody().ClearPivotOffsetByInstigator(this);
		Game::GetCody().ClearPivotLagSpeedByInstigator(this);
		Game::GetCody().ClearIdealDistanceByInstigator(this);
		Game::GetCody().ClearCameraSettingsByInstigator(this);
	}
}