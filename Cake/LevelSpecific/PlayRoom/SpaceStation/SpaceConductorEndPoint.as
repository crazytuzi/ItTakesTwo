class ASpaceConductorEndPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	bool bConnected = false;

	UFUNCTION()
	void SetConnectedStatus(bool bStatus)
	{
		if (bConnected != bStatus)
		{
			bConnected = bStatus;
			BP_SetConnectedStatus(bConnected);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetConnectedStatus(bool bStatus) {}
}