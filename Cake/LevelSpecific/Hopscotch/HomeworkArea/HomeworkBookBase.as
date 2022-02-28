UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkBookBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(meta = (MakeEditWidget))
	FVector HiddenLoc;

	UPROPERTY(meta = (MakeEditWidget))
	FVector VisibleLoc;

	UPROPERTY()
	FHazeTimeLike ShowBookTimeline;
	default ShowBookTimeline.Duration = 1.f;

	FVector HiddenLocWorld;
	FVector VisibleLocWorld;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShowBookTimeline.BindUpdate(this, n"ShowBookTimelineUpdate");
		HiddenLocWorld = GetActorTransform().TransformPosition(HiddenLoc);
		VisibleLocWorld = GetActorTransform().TransformPosition(VisibleLoc);
	}

	UFUNCTION()
	void PlayTimeline()
	{
		ShowBookTimeline.PlayFromStart();
	}

	UFUNCTION()
	void ShowBookTimelineUpdate(float CurrentValue)
	{
		SetActorLocation(FMath::VLerp(HiddenLocWorld, VisibleLocWorld, FVector(CurrentValue, CurrentValue, CurrentValue)));
	}
}