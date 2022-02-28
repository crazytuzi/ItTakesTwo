import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;

event void FNotifyEndSessionComplete();
event void FNotifyDisableStone(ACurlingStone Stone);

class ACurlingResetVolume : AHazeActor
{
	FNotifyEndSessionComplete EventNotifyEndSessionComplete; 
	FNotifyDisableStone EventNotifyDisableStone;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	int StoneCount;
	int MaxStoneCount = 6; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	}

	void ResetStoneCount()
	{
		StoneCount = 0;
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		ACurlingStone CurlingStone = Cast<ACurlingStone>(OtherActor);

		if (CurlingStone == nullptr)
			return;
		
		if (HasControl())
		{
			ResetAndCheckStones(CurlingStone);
		}
		
		CurlingStone.AudioEndGlideEvent();
    }

	UFUNCTION(NetFunction)
	void ResetAndCheckStones(ACurlingStone InputCurlingStone)
	{
		InputCurlingStone.ResetPositionAndState();
		InputCurlingStone.EnablePlayerInteraction();
		EventNotifyDisableStone.Broadcast(InputCurlingStone);

		if (StoneCount < MaxStoneCount - 1)
		{
			StoneCount++;
		}	
		else 
		{
			StoneCount = 0;
			
			if (HasControl())
				System::SetTimer(this, n"BroadcastEndSession", 0.8f, false);
		}
	}

	UFUNCTION()
	void BroadcastEndSession()
	{
		EventNotifyEndSessionComplete.Broadcast();
	}
}