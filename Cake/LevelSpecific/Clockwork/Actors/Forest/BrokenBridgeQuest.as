import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

event void FOnBrokenBridgeMended();

class ABrokenBridgeQuest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY()
	FOnBrokenBridgeMended OnBridgeMended;

	TArray<AActor> ActorArray;

	TArray<UTimeControlActorComponent> TimeCompArray; 

	bool bIsMended = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		BoxCollision.GetOverlappingActors(ActorArray);

		for (AActor Actor : ActorArray)
		{
			UTimeControlActorComponent TimeComp; 
			TimeComp = Cast<UTimeControlActorComponent>(Actor.GetComponentByClass(UTimeControlActorComponent::StaticClass()));

			if (TimeComp != nullptr)
				TimeCompArray.Add(TimeComp);
		}

		TimeCompArray[0].TimeFullyReversedEvent.AddUFunction(this, n"FullyReversed");
	}

	UFUNCTION()
	void FullyReversed()
	{
		if (!bIsMended)
		{
			for(UTimeControlActorComponent Comp : TimeCompArray)
				Comp.DisableTimeControl(this);

			bIsMended = true;
			OnBridgeMended.Broadcast();
		}
	}
}