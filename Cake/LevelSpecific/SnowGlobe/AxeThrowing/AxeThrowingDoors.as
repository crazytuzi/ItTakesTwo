class AAxeThrowingDoors : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FenceMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent, Attach = FenceMesh)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(Category = "Capabilities")
	TSubclassOf<UHazeCapability> DoorCapability;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DoorOpen;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DoorClose;

	FVector ClosedPos;
	FVector OpenPos;

	bool bDoorsAreOpen;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ClosedPos = FenceMesh.RelativeLocation;

		OpenPos = FenceMesh.RelativeLocation + FVector(0.f, 0.f, 700.f);

		AddCapability(DoorCapability);
	}

	void SetDoorOpen()
	{
		bDoorsAreOpen = true;
		AkComp.HazePostEvent(DoorOpen);
	}

	void SetDoorClosed()
	{
		bDoorsAreOpen = false;
		AkComp.HazePostEvent(DoorClose);
	}
}