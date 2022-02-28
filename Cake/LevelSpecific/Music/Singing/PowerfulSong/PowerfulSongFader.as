import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class APowerfulSongFader : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USongReactionComponent SongReaction;

	UPROPERTY()
	bool FlipDesiredEnd;

	float ProgressOnSpline;

	float Force;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	void OnImpact(FPowerfulSongInfo Info)
	{
		Force += 4500;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Force = FMath::Lerp(Force, -1000.f, DeltaTime);

		

		if (ProgressOnSpline == 0 && Force < 0)
		{
			Force = 0;
		}

		ProgressOnSpline = FMath::Lerp(ProgressOnSpline, ProgressOnSpline + Force, DeltaTime);

		ProgressOnSpline = FMath::Clamp(ProgressOnSpline, 0, Spline.SplineLength);

		FVector WorldLoc = Spline.GetLocationAtDistanceAlongSpline(ProgressOnSpline, ESplineCoordinateSpace::World);
		Mesh.SetWorldLocation(WorldLoc);
	}
}