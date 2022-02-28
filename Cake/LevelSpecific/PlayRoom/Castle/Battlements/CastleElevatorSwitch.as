class ACastleElevatorSwitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbVisualizeComponent(true);

	UPROPERTY()
	bool bActive = false;

	UFUNCTION(BlueprintEvent)
	void ActivateSwitch()
	{
		bActive = true;
	}

	UFUNCTION(BlueprintEvent)
	void DeactivateSwitch()
	{
		bActive = false;
	}
}