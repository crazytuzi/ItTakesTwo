class UWaspGrindBlockerComponent : USceneComponent
{
	UPROPERTY()
	AHazeActor StartPosition;

	UPROPERTY()
	AHazeActor EndPosition;

	UPROPERTY()
	bool bStartBlock;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.DisableActor(Owner);
	}

	UFUNCTION()
	void SetBlocking()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.EnableActor(Owner);
		bStartBlock = true;
	}

	UFUNCTION()
	void FlyAway()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.SetCapabilityActionState(n"FlyAway", EHazeActionState::Active);
	}
}