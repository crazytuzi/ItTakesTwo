import Vino.Interactions.InteractionComponent;

class ASpaCaterPillarMassage : AHazeCharacter
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)	
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 30000.f;

	UPROPERTY()
	bool bEnter = false;
	UPROPERTY()
	bool bExit = false;
	UPROPERTY()
	bool bIsCody;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		if(Player == Game::GetCody())
			bIsCody = true;
		if(Player == Game::GetMay())
			bIsCody = false;

		bEnter = true;
		bExit = false;
    }
	
	UFUNCTION()
    void OnInteractionDeactivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		bEnter = false;
		bExit = true;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		#if EDITOR
			if(bHazeEditorOnlyDebugBool)
			{
				Print("bExit" + bExit);
				Print("bEnter" + bEnter);
				Print("bIsCody" + bIsCody);
			}
		#endif
	}
}

