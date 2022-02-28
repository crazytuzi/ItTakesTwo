event void FOnChangeClockBossCam(int CamID);
event void FOnEndClockBossCam(int CamID);

class AClockworkLastBossChangeCameraVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;

	UPROPERTY()
	int CameraID = 0;

	UPROPERTY()
	FOnChangeClockBossCam OnChangeCam;

	UPROPERTY()
	FOnEndClockBossCam OnEndCam;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnComponentBeginOverlap.AddUFunction(this, n"BoxOverlap");
		Box.OnComponentEndOverlap.AddUFunction(this, n"BoxEndOverlap");
	}

	UFUNCTION()
	void BoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OnChangeCam.Broadcast(CameraID);		
	}

	UFUNCTION()
	void BoxEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OnEndCam.Broadcast(CameraID);
	}
}