import Vino.Interactions.InteractionComponent;

class ASpaButterFly : AHazeCharacter
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

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component)
    {
		bEnter = true;
		bExit = false;
    }
	
	UFUNCTION()
    void OnInteractionDeactivated(UInteractionComponent Component)
    {
		bEnter = false;
		bExit = true;
    }
}

