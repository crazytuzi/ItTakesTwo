
class UDJStationUIWidget : UHazeUserWidget
{
	private bool bIsInteracting = false;

	// When a player activates this dj-stand by moving close enough to it. The player should be able to interact witht his DJ stand after this has been called
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Player Interaction Begin"))
	void BP_OnPlayerInteractionBegin(AHazePlayerCharacter InPlayer) {}
	void OnPlayerInteractionBegin(AHazePlayerCharacter InPlayer) 
	{
		if(bIsInteracting)
			return;

		bIsInteracting = true;
		BP_OnPlayerInteractionBegin(InPlayer);
	}

	// When a player that used to interact with thsi dj-stand no longer does so, most likely by moving away from it.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Player Interaction End"))
	void BP_OnPlayerInteractionEnd(AHazePlayerCharacter InPlayer) {}
	void OnPlayerInteractionEnd(AHazePlayerCharacter InPlayer) 
	{
		if(!bIsInteracting)
			return;

		bIsInteracting = false;
		BP_OnPlayerInteractionEnd(InPlayer);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Progress Increased"))
	void BP_OnProgressIncreased() {}
	void OnProgressIncreased() 
	{
		if(!bIsInteracting)
			return;
		
		BP_OnProgressIncreased();
	}
}
