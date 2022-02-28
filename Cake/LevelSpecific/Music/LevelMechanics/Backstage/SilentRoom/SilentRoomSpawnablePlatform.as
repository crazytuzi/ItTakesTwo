class ASilentRoomSpawnablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh02;

	UPROPERTY()
	FHazeTimeLike ShowSilentRoomPlatformTimeline;
	default ShowSilentRoomPlatformTimeline.Duration = 0.5f;

	UPROPERTY()
	bool bPreviewTargetLocation = false;
	
	FVector StartLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, 0.f, 4000.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShowSilentRoomPlatformTimeline.BindUpdate(this, n"ShowPlatformTimeline");

		MeshRoot.SetRelativeLocation(StartLoc);	
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewTargetLocation)
			MeshRoot.SetRelativeLocation(TargetLoc);
		else
			MeshRoot.SetRelativeLocation(StartLoc);
	}

	UFUNCTION()
	void SetPlatformActive(bool bActive)
	{
		bActive ? ShowSilentRoomPlatformTimeline.Play() : ShowSilentRoomPlatformTimeline.Reverse(); 
	}
	
	UFUNCTION()
	void ShowPlatformTimeline(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
	}
}