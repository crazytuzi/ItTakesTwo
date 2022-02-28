event void WallSlideBoxActivated(bool bInvertedOffset);

class ASilentRoomWallSlidePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent LeftBox;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent RightBox;

	UPROPERTY()
	WallSlideBoxActivated WallSlideBoxAcitvatedEvent;

	UPROPERTY()
	bool bLeftBoxActive = true;

	UPROPERTY()
	bool bRightBoxActive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bLeftBoxActive)
			LeftBox.OnComponentBeginOverlap.AddUFunction(this, n"LeftBoxOverlap");

		if (bRightBoxActive)
			RightBox.OnComponentBeginOverlap.AddUFunction(this, n"RightBoxOverlap");
	}

	UFUNCTION()
	void LeftBoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		if (Player != Game::GetCody())
			return;
		
		WallSlideBoxAcitvatedEvent.Broadcast(true);
	}

	UFUNCTION()
	void RightBoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		if (Player != Game::GetCody())
			return;
		
		WallSlideBoxAcitvatedEvent.Broadcast(false);	
	}
}