import Vino.Buttons.GroundPoundButton;
class AFlippingPlatformsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TArray<AGroundPoundButton> GroundPoundButtonArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundButtonArray[0].OnButtonGroundPoundStarted.AddUFunction(this, n"Button00GroundPounded");
		GroundPoundButtonArray[1].OnButtonGroundPoundStarted.AddUFunction(this, n"Button01GroundPounded");
		GroundPoundButtonArray[2].OnButtonGroundPoundStarted.AddUFunction(this, n"Button02GroundPounded");
	}

	UFUNCTION()
	void Button00GroundPounded(AHazePlayerCharacter Player)
	{
		GroundPoundButtonArray[1].ResetButton();
		GroundPoundButtonArray[2].ResetButton();
	}

	UFUNCTION()
	void Button01GroundPounded(AHazePlayerCharacter Player)
	{
		GroundPoundButtonArray[0].ResetButton();
		GroundPoundButtonArray[2].ResetButton();
	}

	UFUNCTION()
	void Button02GroundPounded(AHazePlayerCharacter Player)
	{
		GroundPoundButtonArray[0].ResetButton();
		GroundPoundButtonArray[1].ResetButton();
	}
}