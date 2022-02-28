UCLASS(Abstract)

event void FOnPlayerEnteredBridge(AHazePlayerCharacter Player);
event void FOnPlayerLeftBridge(AHazePlayerCharacter Player);

class  AJoysRoomBridge : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent BoxCollider;

	UPROPERTY()
	FOnPlayerEnteredBridge OnPlayerEnteredBridge;

	UPROPERTY()
	FOnPlayerLeftBridge OnPlayerLeftBridge;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollider.OnComponentBeginOverlap.AddUFunction(this, n"BoxCollisionBeginOverlap");
		BoxCollider.OnComponentEndOverlap.AddUFunction(this, n"BoxCollisionExitOverlap");
	}


	UFUNCTION()
	void BoxCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if(Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			OnPlayerEnteredBridge.Broadcast(Player);			
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void BoxCollisionExitOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if(Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			OnPlayerLeftBridge.Broadcast(Player);			
		}
	}

	

}