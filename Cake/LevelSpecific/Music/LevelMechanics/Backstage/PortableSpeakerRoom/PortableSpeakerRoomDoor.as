class APortableSpeakerRoomDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	float TimelineDuration = 2.f;

	UPROPERTY()
	FHazeTimeLike MoveDoorTimeline;
	default MoveDoorTimeline.Duration = 4.5f;

	FVector StartLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, 0.f, 1000.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveDoorTimeline.BindUpdate(this, n"MoveDoorTimelineUpdate");
		MoveDoorTimeline.SetPlayRate(1 / TimelineDuration);
	}

	UFUNCTION()
	void MoveDoorTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void MoveDoor()
	{
		MoveDoorTimeline.PlayFromStart();
	}
}