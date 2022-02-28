class AMusicTechWallDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorOpenAudioEvent;

	UPROPERTY()
	bool bShowTargetLoc = false;

	UPROPERTY()
	FHazeTimeLike MoveDoorTimeline;
	default MoveDoorTimeline.Duration = 0.5f;

	FVector StartingLoc;
	
	UPROPERTY()
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveDoorTimeline.BindUpdate(this, n"MoveDoorTimelineUpdate");
		MeshRoot.SetRelativeLocation(StartingLoc);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetLoc)
			MeshRoot.SetRelativeLocation(TargetLoc);
		else
			MeshRoot.SetRelativeLocation(StartingLoc);
	}

	UFUNCTION()
	void MoveDoorTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartingLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void MoveDoor()
	{
		MoveDoorTimeline.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(DoorOpenAudioEvent, this.GetActorTransform());
	}
}