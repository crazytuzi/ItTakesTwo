import Vino.Triggers.PlayerLookAtTrigger;
import Vino.Triggers.VOBarkTriggerComponent;

class AVOBarkPlayerLookAtTrigger : APlayerLookAtTrigger
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UVOBarkTriggerComponent VOBarkTriggerComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComponent;
	default BillboardComponent.Sprite = Asset("/Engine/EditorResources/AudioIcons/S_Ambient_Sound_Simple.S_Ambient_Sound_Simple");

	// If true, this will only trigger if both players are looking at the LookAtTrigger
	UPROPERTY(Category = "VOBark")
	bool bBothPlayerTrigger = false;

	UPROPERTY()
	FPlayerLookAtEvent OnBarkTriggered;

	TArray<AHazePlayerCharacter> LookingActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (LookAtTrigger.ReplicationType == EPlayerLookAtTriggerReplication::Local)
			VOBarkTriggerComponent.bTriggerLocally = true;

		VOBarkTriggerComponent.OnVOBarkTriggered.AddUFunction(this, n"BarkTriggered");
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginLookAt(AHazePlayerCharacter Player)
	{
		Super::BeginLookAt(Player);

		LookingActors.AddUnique(Player);

		// VOBark triggering is networked by VOBarkTriggerComponent
		if (bBothPlayerTrigger)
		{
 			if (LookingActors.Num() == 1)
				VOBarkTriggerComponent.SetBarker(Player, true);
			else
				VOBarkTriggerComponent.OnStarted();
		}
		else // !bBothPlayerTrigger
		{
			if (LookingActors.Num() == 1)
				VOBarkTriggerComponent.SetBarker(Player);

			VOBarkTriggerComponent.OnStarted();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EndLookAt(AHazePlayerCharacter Player)
	{
		Super::EndLookAt(Player);

		LookingActors.Remove(Player);

		// VOBark triggering is networked by VOBarkTriggerComponent
		if (bBothPlayerTrigger)
		{
			VOBarkTriggerComponent.OnEnded();
		
			if (LookingActors.Num() > 0)
				VOBarkTriggerComponent.SetBarker(LookingActors[0], true);
		}
		else // !bBothPlayerTrigger
		{
			if (LookingActors.Num() == 0)
				VOBarkTriggerComponent.OnEnded();
			else
				VOBarkTriggerComponent.SetBarker(LookingActors[0]);	
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void BarkTriggered(AHazeActor Actor)
	{
		OnBarkTriggered.Broadcast(Cast<AHazePlayerCharacter>(Actor));
	}

}