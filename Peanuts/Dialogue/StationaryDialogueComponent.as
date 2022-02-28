delegate void FOnStationaryDialogueFinished();

class UStationaryDialogueComponent : UActorComponent
{
	UPROPERTY()
	AHazeCameraActor Camera;

	FOnStationaryDialogueFinished OnFinished;

	bool bIsInStationaryDialogue = false;
}