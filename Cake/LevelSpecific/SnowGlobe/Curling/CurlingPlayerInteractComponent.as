import Vino.Tutorial.TutorialStatics;

enum EInteractionState
{
	Default,
	Tutorial,
	Interacting,
	Cancelling
}

class UCurlingPlayerInteractComponent : UActorComponent
{
	FVector InteractionLocation;

	EInteractionState InteractionState;

	AHazeActor TubeLookAtObj;
	AHazeActor DoorLookAtObj;

	bool bTutorialActive;

	bool bLookAtDoors;
	bool bLookAtTube;

	void ActivateCancelPrompt(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	void DeactivateCancelPrompt(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}
}