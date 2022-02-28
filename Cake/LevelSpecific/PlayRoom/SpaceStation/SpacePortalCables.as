UCLASS(Abstract)
class ASpacePortalCables : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	bool bActive = false;

	UFUNCTION()
	void ActivateSpaceCables()
	{
		if (bActive)
			return;

		bActive = true;
		BP_ActivateSpaceCables();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateSpaceCables() {}
}