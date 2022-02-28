
class UMicrophoneChaseRespawnSplineRegion : UHazeSplineRegionComponent
{
	// Override the color that is used to visualize the region in the editor.
	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Purple;
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		EnteringActor.BlockCapabilities(n"Respawn", this);
		//PrintToScreen("Respawn blocked for: " + EnteringActor.Name, 3.0f);
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionExit(AHazeActor ExitingActor, ERegionExitReason ExitReason)
	{
		ExitingActor.UnblockCapabilities(n"Respawn", this);
		//PrintToScreen("Respawn UNblocked for: " + ExitingActor.Name, 3.0f);
	}
}
