import Cake.LevelSpecific.Music.Cymbal.CymbalReceptacle;

class APortableSpeakerRoomRotatingSpeakerMount : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	ACymbalReceptacle ConnectedCymbalReceptacle;

	UPROPERTY()
	FHazeTimeLike RotateActorTimeline;
	default RotateActorTimeline.Duration = 1.f;

	UPROPERTY()
	TArray<AActor> ActorsToAttach;
	
	FRotator StartRot = FRotator::ZeroRotator;
	FRotator TargetRot = FRotator(0.f, 180.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConnectedCymbalReceptacle.OnCymbalAttached.AddUFunction(this, n"CymbalAttached");
		ConnectedCymbalReceptacle.OnCymbalDetached.AddUFunction(this, n"CymbalDetached");

		RotateActorTimeline.BindUpdate(this, n"RotateActorTimelineUpdate");

		for (AActor Actor : ActorsToAttach)
		{
			Actor.AttachToComponent(MeshRoot, n"", EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION()
	void RotateActorTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartRot, TargetRot, CurrentValue));
	}

	UFUNCTION()
	void CymbalAttached()
	{
		RotateActorTimeline.Play();
	}

	UFUNCTION()
	void CymbalDetached()
	{
		RotateActorTimeline.Reverse();
	}
}