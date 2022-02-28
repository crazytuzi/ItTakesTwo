import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.SilentRoomSpawnablePlatform;
import Cake.LevelSpecific.Music.Cymbal.CymbalReceptacle;

class ASilentRoomSpawnablePlatformManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	ACymbalReceptacle CymbalReceptacle;

	UPROPERTY()
	TArray<ASilentRoomSpawnablePlatform> PlatformArray;

	float Timer = 0.f;
	float TimerMax = 0.1f;

	int PlatformArrayIndex = 0;

	bool bForward;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		CymbalReceptacle.OnCymbalAttached.AddUFunction(this, n"CymbalAttached");
		CymbalReceptacle.OnCymbalDetached.AddUFunction(this, n"CymbalDetached");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Timer += DeltaTime;

		if (Timer >= TimerMax)
		{
			PlatformArray[PlatformArrayIndex].SetPlatformActive(bForward);
			Timer = 0.f;
			PlatformArrayIndex++;
			
			if (PlatformArrayIndex == PlatformArray.Num())
			{
				SetActorTickEnabled(false);
			}
		}
	}

	UFUNCTION()
	void CymbalAttached()
	{
		bForward = true;
		PlatformArrayIndex = 0;
		SetActorTickEnabled(true);

	}

	UFUNCTION()
	void CymbalDetached()
	{
		bForward = false;
		PlatformArrayIndex = 0;
		SetActorTickEnabled(true);
	}
}