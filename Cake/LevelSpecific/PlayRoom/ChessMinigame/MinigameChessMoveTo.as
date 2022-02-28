
struct FMinigameChessMoveToTimes
{
	/** 
	 *@Time: the length to traget location is reached
	 *@Value: the percentage of the move (0 - 1)
	*/
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveCurve;


	/** 
	 *@Time: the length to the landing happens
	 *@Value: the percentage of the max height (0 - 1)
	*/
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve JumpCurve;

	/** When the piece counts as grounded again */
	UPROPERTY(EditDefaultsOnly)
	float TotalAnimationTime = 0;
};

struct FMinigameChessMoveTo
{
	bool bHasMove = false;
	FMinigameChessMoveToTimes Move;
	float ActiveTime = 0.f;
	FVector StartLocation;
	FVector TargetLocation;
	float MaxAirHeight = 0;
	float LandingTime = 0;

	void InitializeMove(FVector From, FVector To, float MaxHeight, FMinigameChessMoveToTimes WithMove)
	{	
		bHasMove = true;
		Move = WithMove;
	
		Move.JumpCurve.GetTimeRange(ActiveTime, LandingTime);
		ActiveTime = 0.f;

		StartLocation = From;
		TargetLocation = To;
		MaxAirHeight = MaxHeight;
	}

	bool IsActive() const
	{
		if(!bHasMove)
			return false;

		if(Move.JumpCurve.NumKeys <= 0)
			return false;

		if(ActiveTime >= Move.TotalAnimationTime)
			return false;

		return true;
	}

	bool HasLanded() const
	{
		return ActiveTime >= LandingTime;
	}

	float GetRemaningTime() const
	{
		return FMath::Max(Move.TotalAnimationTime - ActiveTime, 0.f);	
	}
}