import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObject;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObjectsManager;

event void FClockWorkLastBossOverlapActorSignature(EClockworkMoveNumber ClockworkMoveNumber, bool bOverrideStartDelay, float StartInterval, bool bShouldRemoveActors);
event void FClockWorkLastBossOverlapActorSignatureEvent(EClockworkEventNumber EventNumber);

class AClockworkLastBossOverlapActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxCollision;
	default BoxCollision.LineThickness = 35.f;

	UPROPERTY(Category = "Trigger")
	bool bShouldOnlyTriggerOnce = true;

	UPROPERTY(Category = "Trigger")
	bool bBothPlayersMustTrigger = false;

	UPROPERTY(Category = "Moving Objects")
	bool bShouldTriggerMoveObject = false;

	UPROPERTY(Category = "Moving Objects", Meta = (EditCondition = "bShouldTriggerMoveObject"))
	EClockworkMoveNumber ClockworkMoveNumber;

	UPROPERTY(Category = "Moving Objects", Meta = (EditCondition = "bShouldTriggerMoveObject"))
	float IntervalBetweenMoves = 0.f;

	UPROPERTY(Category = "Moving Objects", Meta = (EditCondition = "bShouldTriggerMoveObject"))
	bool bShouldRemoveActors = false;

	UPROPERTY(Category = "Boss Events")
	bool bShouldTriggerEvent = false;

	UPROPERTY(Category = "Boss Events", Meta = (EditCondition = "bShouldTriggerEvent"))
	EClockworkEventNumber ClockworkEventNumber;

	UPROPERTY()
	FClockWorkLastBossOverlapActorSignature MoveObjectOverlappedWasTriggered;

	UPROPERTY()
	FClockWorkLastBossOverlapActorSignatureEvent EventOverlapWasTriggered;

	private bool bHasBeenTriggered = false;
	private TArray<AHazePlayerCharacter> PlayersThatHaveTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	UFUNCTION(NetFunction)
	void NetTriggerPlayer(AHazePlayerCharacter Player)
	{
		PlayersThatHaveTriggered.AddUnique(Player);

		if (bHasBeenTriggered)
			return;

		if (bBothPlayersMustTrigger)
		{
			// When both players must trigger the trigger's control side decides
			if (HasControl() && PlayersThatHaveTriggered.Num() == 2)
			{
				NetTriggerEvents();
			}
		}
		else
		{
			// When only one player is needed to trigger, we can just activate the events
			// straight away when the first player enters.
			TriggerEvents();
		}
	}

	UFUNCTION(NetFunction)
	void NetRemovePlayer(AHazePlayerCharacter Player)
	{
		PlayersThatHaveTriggered.Remove(Player);
	}

	void TriggerEvents()
	{
		bHasBeenTriggered = true;

		if (bShouldTriggerMoveObject)
		{
			if (bShouldRemoveActors)
				GetClockworkLastBossMovingObjectsManager().RemoveMovingObjects(ClockworkMoveNumber, IntervalBetweenMoves);
			else
				GetClockworkLastBossMovingObjectsManager().StartMovingObjects(ClockworkMoveNumber, IntervalBetweenMoves);
		}

		if (bShouldTriggerEvent)
			EventOverlapWasTriggered.Broadcast(ClockworkEventNumber);
	}

	UFUNCTION(NetFunction)
	void NetTriggerEvents()
	{
		TriggerEvents();
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player.HasControl())
			NetTriggerPlayer(Player);
    }

	UFUNCTION()
	void TriggeredOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player.HasControl())
			NetRemovePlayer(Player);
	}
}