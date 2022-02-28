import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossEventBase;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObjectsManager;

class AClockworkLastBossRecordCrusherEvent : AClockworkLastBossEventBase
{
	
	AClockworkLastBossMovingObjectsManager MovingObjectsManager;

	// float MoveObject05Timer = 1.f;
	// float MoveObject06Timer = 6.f;
	// float MoveObject07Timer = 11.f; 

	float MoveObject05Timer = 1.f;
	float MoveObject06Timer = 1.f;
	float MoveObject07Timer = 1.f;

	bool bObjects05Moved = false;
	bool bObjects06Moved = false;
	bool bObjects07Moved = false;

	bool bEventIsActive = false;

	//float EventTimer = 23.f;
	float EventTimer = 9.f;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		TArray<AClockworkLastBossMovingObjectsManager> TempArray;
		GetAllActorsOfClass(TempArray);
		MovingObjectsManager = TempArray[0];
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (!bEventIsActive)
			return;

		MoveObject05Timer -= DeltaTime;
		MoveObject06Timer -= DeltaTime;
		MoveObject07Timer -= DeltaTime;

		if (MoveObject05Timer <= 0.f && !bObjects05Moved)
		{
			bObjects05Moved = true;
			MovingObjectsManager.StartMovingObjects(EClockworkMoveNumber::Move05);
		}

		if (MoveObject06Timer <= 0.f && !bObjects06Moved)
		{
			bObjects06Moved = true;
			//MovingObjectsManager.StartMovingObjects(EClockworkMoveNumber::Move06);s
		}

		if (MoveObject07Timer <= 0.f && !bObjects07Moved)
		{
			bObjects07Moved = true;
			//MovingObjectsManager.StartMovingObjects(EClockworkMoveNumber::Move07);
		}
		
		EventTimer -= DeltaTime;

		if (EventTimer <= 0.f)
			StopEvent03();
	}
	
	UFUNCTION()
	void StartRecordCrusherEvent()
	{
		bEventIsActive = true;
		StartedEvent.Broadcast(EventNumber);
	}

	UFUNCTION()
	void StopEvent03()
	{
		bEventIsActive = false;
		FinishedEvent.Broadcast(EventNumber);
	}
}