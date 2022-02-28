import Cake.LevelSpecific.Hopscotch.HopscotchButton;
import Cake.LevelSpecific.Hopscotch.MovingCardboardBoxes;

event void FMovingCardboardSignature();

class AMovingCardboardBoxesManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TArray<AHopscotchButton> ButtonArray;

	UPROPERTY()
	TArray<AMovingCardboardBoxes> BoxArray;

	UPROPERTY()
	float TimerDuration;
	default TimerDuration = 15.f;

	UPROPERTY()
	FMovingCardboardSignature TimerStartedEvent;

	UPROPERTY()
	FMovingCardboardSignature TimerStopped;

	bool bTimerIsActive;
	bool bPuzzleCompleted;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AHopscotchButton Button : ButtonArray)
		{
			Button.ButtonPressedEvent.AddUFunction(this, n"ButtonPressed");
		}
	}

	UFUNCTION()
	void ButtonPressed(AHopscotchButton Button)
	{
		if (!bTimerIsActive && !bPuzzleCompleted)
		{
			System::SetTimer(this, n"ResetButtons", TimerDuration, false);
			TimerStartedEvent.Broadcast();
			bTimerIsActive = true;
		}
	}

	UFUNCTION()
	void ResetButtons()
	{
		bTimerIsActive = false;

		if (!bPuzzleCompleted)
		{
			TimerStopped.Broadcast();
		
			for (AHopscotchButton Button : ButtonArray)
			{
				Button.ResetButton();
			}

			for (AMovingCardboardBoxes Boxes : BoxArray)
			{
				Boxes.ReverseBox();
			}
		}
	}

	UFUNCTION()
	void PuzzleIsCompleted()
	{
		bPuzzleCompleted = true;
	}
}