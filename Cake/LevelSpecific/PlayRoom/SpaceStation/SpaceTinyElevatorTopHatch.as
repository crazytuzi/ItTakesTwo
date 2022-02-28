class ASpaceTinyElevatorTopHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HatchRoot;

	UFUNCTION()
	void OpenHatch()
	{
		BP_OpenHatch();
	}

	UFUNCTION()
	void CloseHatch()
	{
		BP_CloseHatch();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenHatch() {}

	UFUNCTION(BlueprintEvent)
	void BP_CloseHatch() {}
}