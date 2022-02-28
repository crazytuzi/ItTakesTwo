import Peanuts.ButtonMash.ButtonMashWidget;
import Peanuts.ButtonMash.ButtonMashHandleBase;

#if TEST
const FConsoleVariable CVar_ButtonMashAutoPass("Haze.ButtonMashAutoPass", 0);
#endif

class UButtonMashComponent : UActorComponent
{
	// Capability-classes that are overridden in blueprint
	UPROPERTY(Category = "Capability Classes")
	TSubclassOf<UHazeCapability> DefaultCapabilityClass;

	UPROPERTY(Category = "Capability Classes")
	TSubclassOf<UHazeCapability> ProgressCapabilityClass;

	UButtonMashHandleBase CurrentButtonMash;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Variables for calculating button mash rate
	float TimingWindow = 0.5f;
	float MashTimer = 0.f;

	int PrevMashCount = 0;
	int MashCount = 0;

	void ResetMashRate()
	{
		PrevMashCount = 0;
		MashCount = 0;
		MashTimer = 0.f;
	}

	void StartButtonMash(UButtonMashHandleBase ButtonMash)
	{
		CurrentButtonMash = ButtonMash;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentButtonMash == nullptr)
		{
			SetComponentTickEnabled(false);
			return;
		}

#if TEST
		// Auto-mash when the console variable for it is set to on
		if (CVar_ButtonMashAutoPass.GetInt() != 0)
			MashCount += 1;
#endif

		MashTimer += DeltaTime;

		// When a window is filled, copy it over and start a new one
		if (MashTimer >= TimingWindow)
		{
			PrevMashCount = MashCount;
			MashCount = 0;
			MashTimer -= TimingWindow;
		}

		// Phase over from the previous window to the next window as it gets more accurate over time
		float PrevRate = GetRatePerSecond(PrevMashCount, TimingWindow);
		float CurRate = GetRatePerSecond(MashCount, MashTimer);

		CurrentButtonMash.MashRateControlSide = FMath::Lerp(PrevRate, CurRate, MashTimer / TimingWindow);
	}

	void DoMashPulse()
	{
		MashCount++;
	}

	float GetRatePerSecond(int Presses, float Time)
	{
		// Dont divide by 0
		if (Time == 0.f)
			return 0.f;

		return Presses / Time;
	}
}