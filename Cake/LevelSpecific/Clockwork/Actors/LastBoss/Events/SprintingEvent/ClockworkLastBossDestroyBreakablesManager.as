import Cake.Environment.Breakable;
class AClockworkLastBossDestroyBreakablesManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	float DestroyInterval = 0.5f;
	
	UPROPERTY()
	TArray<ABreakableActor> BreakableArray;
	
	UPROPERTY()
	bool bDebug = false;
	
	bool bManagerActive = false;
	float CurrentDestroyInterval = 0.f;
	int BreakableIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentDestroyInterval = DestroyInterval;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bManagerActive && !bDebug)
			return;

		CurrentDestroyInterval -= DeltaTime;
		if (CurrentDestroyInterval <= 0.f)
		{
			CurrentDestroyInterval = DestroyInterval;
			
			FBreakableHitData HitData;
			BreakableArray[BreakableIndex].BreakableComponent.Break(HitData);
			
			BreakableIndex++;
			
			if (BreakableIndex > BreakableArray.Num() - 1)
			{
				bManagerActive = false;	
				bDebug = false;
			}
		}
	}

	UFUNCTION()
	void SetManagerActive()
	{
		bManagerActive = true;
	}
}