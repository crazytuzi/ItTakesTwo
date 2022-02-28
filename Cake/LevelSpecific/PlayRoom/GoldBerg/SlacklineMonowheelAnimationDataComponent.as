class USlacklineMonoWheelAnimationDataComponent: UActorComponent
{
	UPROPERTY()
	bool IsOnBike  = false;

	UPROPERTY()
	float Velocity;

	UPROPERTY()
	float WheelBalance;

	UPROPERTY()
	float MarbleBalance;

	UPROPERTY()
	bool bBothPlayersOn = false;

	UPROPERTY()
	bool LerpToZero = false;

	UPROPERTY()
	bool FailedBwd = false;

	UPROPERTY()
	bool FailedFwd = false;

	UPROPERTY()
	bool Finished = false;

	UPROPERTY()
	float WheelOffset;
}