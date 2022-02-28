class AClockworkLastBossFreeFallCogWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CogWall;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActivated)
			return;
	}

	UFUNCTION()
	void SetWallActivated(bool bNewActivated)
	{
		bActivated = bNewActivated;
	}

	UFUNCTION()
	void SetCogWallVisible(bool bNewVisible)
	{
		//SetActorHiddenInGame(!bNewVisible);

		TArray<AActor> ActorArray;
		GetAttachedActors(ActorArray);

		if (ActorArray.Num() > 0)
		{
			for (AActor Actor : ActorArray)
			{
				AClockworkLastBossFreeFallCogWall Wall = Cast<AClockworkLastBossFreeFallCogWall>(Actor);
				if (Actor != nullptr)
				{
					//Actor.SetActorHiddenInGame(!bNewVisible);
					return;
				}

			}
		}
	}


}