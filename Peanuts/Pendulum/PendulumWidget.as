class UPendulumWidget : UHazeUserWidget
{
	UPROPERTY()
	float PendulumPosition = 0.f;

	UPROPERTY()
	float SuccessFraction = 0.f;

	UPROPERTY()
	bool bHasInteractingPlayers = false;
}