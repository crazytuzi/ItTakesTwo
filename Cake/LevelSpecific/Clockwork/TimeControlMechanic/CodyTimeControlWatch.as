import Peanuts.Outlines.Outlines;
class ACodyTimeControlWatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase WatchMesh;
	default WatchMesh.AddTag(ComponentTags::HideOnCameraOverlap);
	
	UPROPERTY()
	FTransform BackpackAttachOffset;

	bool bWatchHidden = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachToActor(Game::GetCody(), n"Backpack");
		Root.SetRelativeTransform(BackpackAttachOffset);

		CreateMeshOutlineBasedOnPlayer(WatchMesh, Game::GetCody());
	}

	UFUNCTION()
	void SetTimeControlWatchHidden(bool bNewHidden)
	{
		bWatchHidden = bNewHidden;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetActorHiddenInGame(Root.AttachParent.Owner.bHidden || bWatchHidden);
	}
}