import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Actor Input Cooking LOD Replication")
class PowerfulSongRailCart : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CartMesh;

	UPROPERTY(DefaultComponent)
	UDEPRECATED_PowerfulSongImpactComponent PowerfulSongImpactComp;

	UPROPERTY(Category = "Properties")
	AHazeActor TargetSplineActor;

	USplineComponent TargetSpline;

	UPROPERTY(Category = "Properties")
	float CurrentDistanceAlongSpline = 0.f;

	UPROPERTY(Category = "Properties")
	float SpeedPerPush = 500.f;

	float CurrentSpeedAlongSpline = 0.f;
	float MaximumPitchModifier = 500.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSplineActor == nullptr)
			return;

		TargetSpline = USplineComponent::Get(TargetSplineActor);
		if (TargetSpline == nullptr)
			return;

		FTransform CurTransform = TargetSpline.GetTransformAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocationAndRotation(CurTransform.Location, CurTransform.Rotation.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetSplineActor != nullptr)
			TargetSpline = USplineComponent::Get(TargetSplineActor);

		PowerfulSongImpactComp.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}

	UFUNCTION(NotBlueprintCallable)
	void PowerfulSongImpact(FVector Direction)
	{
		FVector SplineDir = TargetSpline.GetDirectionAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		float DirDot = Direction.DotProduct(SplineDir);
		CurrentSpeedAlongSpline = 4000.f * DirDot;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetSpline == nullptr)
			return;

		CurrentSpeedAlongSpline = FMath::FInterpTo(CurrentSpeedAlongSpline, 0.f, DeltaTime, 2.f);
		CurrentDistanceAlongSpline += CurrentSpeedAlongSpline * DeltaTime;

		float CurrentPitch = TargetSpline.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World).Pitch;
		if (FMath::Abs(CurrentPitch) > 1.f)
		{
			float PitchModifier = CurrentPitch * 100.f;
			PitchModifier = FMath::Clamp(PitchModifier, -MaximumPitchModifier, MaximumPitchModifier);
			CurrentDistanceAlongSpline -= PitchModifier * DeltaTime;
		}

		CurrentDistanceAlongSpline = FMath::Clamp(CurrentDistanceAlongSpline, 0.f, TargetSpline.SplineLength);

		FTransform CurTransform = TargetSpline.GetTransformAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocationAndRotation(CurTransform.Location, CurTransform.Rotation.Rotator());
	}
}