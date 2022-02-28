import Peanuts.Triggers.ActorTrigger;
import Vino.Triggers.VOBarkTriggerComponent;

class AVOBarkActorTrigger : AActorTrigger
{
	default BrushColor = FLinearColor::Teal;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UVOBarkTriggerComponent VOBarkTriggerComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComponent;
	default BillboardComponent.Sprite = Asset("/Engine/EditorResources/AudioIcons/S_Ambient_Sound_Simple.S_Ambient_Sound_Simple");

	UPROPERTY()
	FActorTriggerEvent OnBarkTriggered;

	TArray<AHazeActor> EnteredActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VOBarkTriggerComponent.bTriggerLocally = bTriggerLocally;

		OnActorEnter.AddUFunction(this, n"Enter");
		OnActorLeave.AddUFunction(this, n"Leave");
		VOBarkTriggerComponent.OnVOBarkTriggered.AddUFunction(this, n"BarkTriggered");
	}

	UFUNCTION(NotBlueprintCallable)
	void Enter(AHazeActor Actor)
	{
		EnteredActors.AddUnique(Actor);

		VOBarkTriggerComponent.SetBarker(Actor);
		VOBarkTriggerComponent.OnStarted();
	}

	UFUNCTION(NotBlueprintCallable)
	void Leave(AHazeActor Actor)
	{
		EnteredActors.Remove(Actor);

		if (EnteredActors.Num() > 0)
		{
			VOBarkTriggerComponent.SetBarker(EnteredActors[0]);
			return;
		}
		
		VOBarkTriggerComponent.OnEnded();
	}

	UFUNCTION(NotBlueprintCallable)
	void BarkTriggered(AHazeActor Actor)
	{
		OnBarkTriggered.Broadcast(Actor);
	}

}