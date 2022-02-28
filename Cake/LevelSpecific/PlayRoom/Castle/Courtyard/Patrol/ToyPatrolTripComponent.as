event void FOnTripSignature(AHazeActor Instigator, FVector Direction, float Duration);

class UToyPatrolTripComponent : UActorComponent
{
	UPROPERTY()
	FOnTripSignature OnTrip;

	UPROPERTY()
	float TripDuration = 1.8f;

	UFUNCTION()
	void Trip(AHazeActor Actor, FVector Direction, float OverrideDuration = -1.f)
	{
		if ((Actor == nullptr && HasControl()) || Actor.HasControl())
			NetTrip(Actor, Direction, OverrideDuration);
	}

	UFUNCTION(NetFunction)
	void NetTrip(AHazeActor Actor, FVector Direction, float OverrideDuration = -1.f)
	{
		OnTrip.Broadcast(Actor, Direction, (OverrideDuration <= 0.f) ? TripDuration : OverrideDuration);
	}
}