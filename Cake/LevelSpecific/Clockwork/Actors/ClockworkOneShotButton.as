import Vino.Buttons.OneShotButton;

class AClockworkOneShotButton : AOneShotButton
{
	UPROPERTY(DefaultComponent, Attach = ButtonBase)
	UStaticMeshComponent LeftCog;

	UPROPERTY(DefaultComponent, Attach = ButtonBase)
	UStaticMeshComponent RightCog;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnButtonPressed.AddUFunction(this, n"BeakPulled");
	}

	UFUNCTION()
	void BeakPulled()
	{
		BP_BeakPulled();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BeakPulled() {}
}