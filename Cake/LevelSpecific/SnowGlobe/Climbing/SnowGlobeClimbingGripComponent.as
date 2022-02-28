event void FOnGripBegin(AHazePlayerCharacter Player);
event void FOnGripEnd(AHazePlayerCharacter Player);

class USnowGlobeClimbingGripComponent : UActorComponent
{
	UPROPERTY()
	FOnGripBegin OnGripBegin;

	UPROPERTY()
	FOnGripEnd OnGripEnd;

	bool bGrippable = true;

	UFUNCTION()
	void SetGripEnable(bool State)
	{
		bGrippable = State;
	}
}