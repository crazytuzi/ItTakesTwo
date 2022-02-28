import Peanuts.ButtonMash.Silent.ButtonMashSilent;

class UPlayerScratchComponent : UActorComponent
{
	UButtonMashSilentHandle MashHandle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MashHandle = StartButtonMashSilent(Cast<AHazePlayerCharacter>(Owner));
	}

	float GetScratchValue() const
	{
		return MashHandle.MashRateControlSide;
	}
}
