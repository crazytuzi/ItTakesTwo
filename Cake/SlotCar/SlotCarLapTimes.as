struct FSlotCarLapTimes
{
	UPROPERTY()
	TArray<float> LapTimes;

	int TargetLaps = 0;
	UPROPERTY()
	bool bLapStarted = false;
	UPROPERTY()
	bool bRaceStarted = false;

	UPROPERTY()
	float CurrentLapTime = 0.f;

	UPROPERTY()
	float BestLapTime = 0.f;

	UPROPERTY()
	float LastLapTime = 0.f;

	void LapCompleted(float LapTime)
	{
		if (!bLapStarted)
		{
			bLapStarted = true;
			return;
		}

		// Store the last lap
		LapTimes.Add(LapTime);

		LastLapTime = LapTime;

		if (BestLapTime == 0.f)
			BestLapTime = LastLapTime;
		else
			BestLapTime = FMath::Min(BestLapTime, LastLapTime);

		CurrentLapTime = 0.f;
	}

	void RaceStarted()
	{
		bLapStarted = true;
	}

	void PrepareForRaceStart(int _TargetLaps)
	{
		LapTimes.Reset();
		bLapStarted = false;
		bRaceStarted = true;
		TargetLaps = _TargetLaps;
		CurrentLapTime = 0.f;
	}

	void RaceEnded()
	{
		bRaceStarted = false;
		TargetLaps = 0;
	}

	bool HasCompletedRace()
	{
		if (!bRaceStarted)
			return false;

		if (NumberOfLaps > TargetLaps)
			return true;
		
		return false;
	}

	int GetNumberOfLaps() const property
	{
		return bRaceStarted ? LapTimes.Num() + 1 : LapTimes.Num();
	}

	void LeftTrack()
	{
		bLapStarted = false;
		bRaceStarted = false;
		CurrentLapTime = 0.f;
	}

	float GetTotalRaceTime() property
	{
		float RaceTime = 0.f;
		int RaceLaps = FMath::Min(TargetLaps, NumberOfLaps - 1);

		for (int Index = 0; Index < RaceLaps; Index ++)
		{
			RaceTime += LapTimes[Index];
		}
		return RaceTime;
	}
}