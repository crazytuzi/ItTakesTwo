class UTrapezeAnimationDataComponent : UActorComponent
{
	// Value between -1 and 1 where negative means going backwards and viceversa
	UPROPERTY()
	float SwingValue;

	UPROPERTY()
	bool bHasMarble = false;

	UPROPERTY()
	bool bIsReaching = false;

	UPROPERTY()
	bool bIsThrowing = false;

	UPROPERTY()
	bool bIsCatching = false;

	void Reset()
	{
		SwingValue = 0.f;

		bHasMarble = false;
	 	bIsReaching = false;
		bIsThrowing = false;
		bIsCatching = false;
	}
}