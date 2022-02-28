import Cake.LevelSpecific.Clockwork.Actors.LowerClocktower.KeyCheckVolume;
class AOpenLargeGateManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TArray<AKeyCheckVolume> KeyCheckVolumes;

	UPROPERTY()
	TArray<AActor> DoorArray;

	UPROPERTY()
	FHazeTimeLike OpenDoorsTimeline;
	default OpenDoorsTimeline.Duration = 4.f;

	FRotator Door01StartRotation;
	FRotator Door01EndRotation;
	FRotator Door02StartRotation;
	FRotator Door02EndRotation;

	int KeyChecksIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AKeyCheckVolume Keys : KeyCheckVolumes)
		{
			Keys.DoorUnlockedEvent.AddUFunction(this, n"KeyVolumeActivated");
		}
		
		OpenDoorsTimeline.BindUpdate(this, n"OpenDoorsTimelineUpdate");

		Door01StartRotation = DoorArray[0].GetActorRotation();
		Door01EndRotation = Door01StartRotation + FRotator(0.f, 120.f, 0.f);

		Door02StartRotation = DoorArray[1].GetActorRotation();
		Door02EndRotation = Door02StartRotation + FRotator(0.f, -120.f, 0.f);
	}

	UFUNCTION()
	void KeyVolumeActivated()
	{
		KeyChecksIndex++;

		if (KeyChecksIndex == 2)
		{
			OpenDoorsTimeline.PlayFromStart();
		}
	}

	UFUNCTION()
	void OpenDoorsTimelineUpdate(float CurrentValue)
	{
		DoorArray[0].SetActorRotation(QuatLerp(Door01StartRotation, Door01EndRotation, CurrentValue));
		DoorArray[1].SetActorRotation(QuatLerp(Door02StartRotation, Door02EndRotation, CurrentValue));
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}