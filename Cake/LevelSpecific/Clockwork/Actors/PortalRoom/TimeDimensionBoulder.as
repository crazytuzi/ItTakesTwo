import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionPickAxeMage;
class ATimeDimensionBoulder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BoulderMesh;

	UPROPERTY()
	ATimeDimensionBoulder ConnectedBoulder;

	UPROPERTY()
	ATimeDimensionPickAxeMage PickAxeMage;

	UPROPERTY()
	FHazeTimeLike RumbleBoulderTimeline;

	UPROPERTY()
	FHazeTimeLike ScaleDownTimeline;
	default ScaleDownTimeline.Duration = 0.3f;

	UPROPERTY()
	UNiagaraSystem NiagaraFX;

	FVector StartingLocation;
	FVector TargetLocation;

	FVector StartingWorldScale;

	int HitIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PickAxeMage != nullptr)
		{
			PickAxeMage.FastScrubEvent.AddUFunction(this, n"FastScrubEvent");
		}

		RumbleBoulderTimeline.BindUpdate(this, n"RumbleBoulderTimelineUpdate");
		ScaleDownTimeline.BindUpdate(this, n"ScaleDownTimelineUpdate");
		ScaleDownTimeline.BindFinished(this, n"ScaleDownTimelineFinished");

		StartingLocation = BoulderMesh.RelativeLocation;
		TargetLocation = StartingLocation + FVector(0.f, 0.f, 40.f);

	 	StartingWorldScale = BoulderMesh.GetWorldScale();
	}

	UFUNCTION()
	void RumbleBoulderTimelineUpdate(float CurrentValue)
	{
		BoulderMesh.SetRelativeLocation(FMath::Lerp(StartingLocation, TargetLocation, CurrentValue));
	}

	UFUNCTION()
	void FastScrubEvent()
	{
		BoulderWasHit();		
	}

	UFUNCTION()
	void ScaleDownBoulder()
	{
		ScaleDownTimeline.PlayFromStart();
	}

	UFUNCTION()
	void ScaleDownTimelineUpdate(float CurrentValue)
	{
		BoulderMesh.SetWorldScale3D(FMath::Lerp(StartingWorldScale, FVector::ZeroVector, CurrentValue));
	}

	UFUNCTION()
	void ScaleDownTimelineFinished(float CurrentValue)
	{
		DestroyActor();
	}

	void BoulderWasHit()
	{
		RumbleBoulderTimeline.PlayFromStart();
		HitIndex++;

		if (HitIndex == 3)
		{
			Niagara::SpawnSystemAtLocation(NiagaraFX, GetActorLocation() + FVector(0.f, 0.f, 1000.f));
			ConnectedBoulder.ScaleDownBoulder();
			DestroyActor();
		}
	}
}