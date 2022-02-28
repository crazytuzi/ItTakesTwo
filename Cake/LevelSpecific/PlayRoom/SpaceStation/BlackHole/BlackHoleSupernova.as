event void FSupernovaFinished();

class ABlackHoleSupernova : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	FSupernovaFinished OnSupernovaFinished;

	UFUNCTION()
	void ActivateSupernova()
	{
		BP_ActivateSupernova();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateSupernova() {}
}