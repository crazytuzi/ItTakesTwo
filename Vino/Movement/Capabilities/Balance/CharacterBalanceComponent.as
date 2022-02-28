class UCharacterBalanceComponent : UActorComponent
{

	UPROPERTY()
	UHazeSplineComponentBase BalanceSpline;

	UFUNCTION()
	void AddSpline(UHazeSplineComponentBase SplineRef)
	{
		BalanceSpline = SplineRef;
	}
	

	UFUNCTION()
	void RemoveSpline(UHazeSplineComponentBase SplineRef)
	{
		BalanceSpline = nullptr;
	}





}