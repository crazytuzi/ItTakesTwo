
event void FKeyBirdDestroyed(AHazeActor KeyBird);
event void FKeyBirdStealKeyStart(AHazeActor KeyBird, AHazeActor Target);
event void FKeyBirdStealKeyStop(AHazeActor KeyBird, AHazeActor Target, bool bSuccess);
event void FKeyBirdSeekKeyStart(AHazeActor KeyBird, AHazeActor TargetKey);
event void FKeyBirdSeekKeyStop(AHazeActor KeyBird, AHazeActor TargetKey, bool bSuccess);

enum EKeyBirdState
{
	RandomMovement,
	SeekKey,
	StealKey,
	SplineMovement,
	MoveToActionLocation,
	None
}

class UKeyBirdBehaviorComponent : UActorComponent
{
	UPROPERTY()
	FKeyBirdDestroyed OnKeyBirdDestroyed;

	UPROPERTY()
	FKeyBirdStealKeyStart OnKeyBirdStealKeyStart;

	UPROPERTY()
	FKeyBirdStealKeyStop OnKeyBirdStealKeyStop;

	UPROPERTY()
	FKeyBirdSeekKeyStart OnKeyBirdSeekKeyStart;

	UPROPERTY()
	FKeyBirdSeekKeyStop OnKeyBirdSeekKeyStop;

	void SetCurrentState(EKeyBirdState NewState) property
	{
		_PreviousState = _CurrentState;
		_CurrentState = NewState;
	}

	EKeyBirdState GetCurrentState() const property { return _CurrentState; }
	EKeyBirdState GetPreviousState() const property { return _PreviousState; }

	private EKeyBirdState _CurrentState = EKeyBirdState::None;
	private EKeyBirdState _PreviousState = EKeyBirdState::None;

	bool bIsDead = false;
}
