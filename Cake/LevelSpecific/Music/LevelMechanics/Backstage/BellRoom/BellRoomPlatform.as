import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BellRoom.BellRoomStatics;

class ABellRoomPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	FHazeTimeLike MovePlatformTimeline;

	UPROPERTY()
	EBellTone ConnectedBellTone;

	UPROPERTY()
	TArray<UMaterialInterface> MaterialArray;

	FVector StartLoc = FVector::ZeroVector;
	
	UPROPERTY(Meta = (MakeEditWidget))
	FVector TargetLoc;

	UPROPERTY()
	float TimelineDuration = 1.f;

	FRotator StartRot;
	FRotator TargetRot;

	UPROPERTY()
	bool bPreviewTargetLocation = false;

	UPROPERTY()
	bool bShouldRotate = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformTimeline.SetPlayRate(1 / TimelineDuration);
		
		MovePlatformTimeline.BindUpdate(this, n"MovePlatformTimelineUpdate");
		MeshRoot.SetRelativeLocation(StartLoc);

		StartRot = MeshRoot.RelativeRotation;
		TargetRot = StartRot - FRotator(0.f, 0.f, -90.f);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PlatformMesh.SetMaterial(0, MaterialArray[ConnectedBellTone]);

		if (bPreviewTargetLocation)
			MeshRoot.SetRelativeLocation(TargetLoc);
		else 
			MeshRoot.SetRelativeLocation(StartLoc);
	}

	UFUNCTION()
	void MovePlatformTimelineUpdate(float CurrentValue)
	{
		if (bShouldRotate)
			MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartRot, TargetRot, CurrentValue));
		else
			MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void PlayTimeline()
	{
		if (!MovePlatformTimeline.IsPlaying())
			MovePlatformTimeline.PlayFromStart();
	}
}