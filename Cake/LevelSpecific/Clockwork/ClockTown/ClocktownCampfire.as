import Vino.Interactions.InteractionComponent;

class AClocktownCampfire : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent InteractionComp;

	bool bLit = false;
	
	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");
    }

    UFUNCTION()
    void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionComp.Disable(n"Used");
		if (!bLit)
			BP_ActivateFire(Player);
		else
			BP_ExtinguishFire(Player);

		bLit = !bLit;
		System::SetTimer(this, n"EnableInteraction", 4.f, false);
    }

	UFUNCTION(NotBlueprintCallable)
	void EnableInteraction()
	{
		InteractionComp.Enable(n"Used");
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateFire(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void BP_ExtinguishFire(AHazePlayerCharacter Player) {}
}