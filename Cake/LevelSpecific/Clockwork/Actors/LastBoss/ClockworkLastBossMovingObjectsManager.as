import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObject;

AClockworkLastBossMovingObjectsManager GetClockworkLastBossMovingObjectsManager()
{
	return Cast<AClockworkLastBossMovingObjectsManager>(Game::GetManagerActor(AClockworkLastBossMovingObjectsManager::StaticClass()));
}

class AClockworkLastBossMovingObjectsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void StartMovingObjects(EClockworkMoveNumber ClockWorkNumber, float IntervalBetweenObjects = 0.f)
	{
		TArray<AClockworkLastBossMovingObject> MovingObjectArray;
		GetAllActorsOfClass(MovingObjectArray);

		float StartInterval = 0.f;
		for (AClockworkLastBossMovingObject Object : MovingObjectArray)
		{
			if (Object.ClockworkMoveNumber == ClockWorkNumber)
			{
				Object.InitiateMove(Delay = StartInterval);
				StartInterval += IntervalBetweenObjects;
			}
		}
	}

	UFUNCTION()
	void RemoveMovingObjects(EClockworkMoveNumber ClockWorkNumber, float IntervalBetweenObjects = 0.f)
	{
		TArray<AClockworkLastBossMovingObject> MovingObjectArray;
		GetAllActorsOfClass(MovingObjectArray);

		float StartInterval = 0.f;
		for (AClockworkLastBossMovingObject Object : MovingObjectArray)
		{
			if (Object.ClockworkMoveNumber == ClockWorkNumber)
			{
				Object.LerpAndRemoveObject(Delay = StartInterval);
				StartInterval += IntervalBetweenObjects;
			}
		}
	}

	UFUNCTION()
	void TeleportObjectsToEndLocation(EClockworkMoveNumber MoveNumber)
	{
		TArray<AClockworkLastBossMovingObject> MovingObjectArray;
		GetAllActorsOfClass(MovingObjectArray);

		for (AClockworkLastBossMovingObject Object : MovingObjectArray)
		{
			if (Object.ClockworkMoveNumber == MoveNumber)
			{
				Object.TeleportToEndLocation();
			}
		}
	}
}