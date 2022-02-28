import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Actor Input Cooking LOD Replication")
class ARailSpeaker : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SpeakerMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongReactionComponent SongReaction;

	UPROPERTY(Category = "Properties")
	AHazeActor TargetSplineActor;

	USplineComponent TargetSpline;

	UPROPERTY(Category = "Properties")
	float CurrentDistanceAlongSpline = 0.f;

	UPROPERTY(Category = "Properties")
	float SpeedPerPush = 500.f;

	UPROPERTY(Category = "Properties")
	float YawOffset = 0.f;

	float CurrentSpeedAlongSpline = 0.f;
	float MaximumPitchModifier = 500.f;

	bool bAligningToTurntable = false;

	FVector CurrentTurntableLocation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSplineActor == nullptr)
			return;

		TargetSpline = USplineComponent::Get(TargetSplineActor);
		if (TargetSpline == nullptr)
			return;

		FTransform CurTransform = TargetSpline.GetTransformAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocationAndRotation(CurTransform.Location, CurTransform.Rotator());
		SpeakerMesh.SetRelativeRotation(FRotator(0.f, YawOffset, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetSplineActor != nullptr)
			TargetSpline = USplineComponent::Get(TargetSplineActor);

		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}

	UFUNCTION(NotBlueprintCallable)
	void PowerfulSongImpact(FVector Direction)
	{
		FVector SplineDir = TargetSpline.GetDirectionAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		float DirDot = Direction.DotProduct(SplineDir);
		CurrentSpeedAlongSpline = 4000.f * DirDot;
	}

	void StartAligningToTurntable(FVector TurntableMiddle)
	{
		CurrentTurntableLocation = TurntableMiddle;
		bAligningToTurntable = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetSpline == nullptr)
			return;

		if (bAligningToTurntable)
		{
			FVector CurDelta = FMath::VInterpTo(ActorLocation, CurrentTurntableLocation, DeltaTime, 2.f);
        	CurDelta = CurDelta - ActorLocation;
			AddActorWorldOffset(CurDelta);
			return;
		}

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
		SetActorLocationAndRotation(CurTransform.Location, CurTransform.Rotator());
		SpeakerMesh.SetRelativeRotation(FRotator(0.f, YawOffset, 0.f));
	}
}