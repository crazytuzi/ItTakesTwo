
class AClawMachineLocationActor: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY()
	float PlayRateReturnLocation = 1;

	UPROPERTY()
	AClawMachineLocationActor North;
	UPROPERTY()
	AClawMachineLocationActor South;
	UPROPERTY()
	AClawMachineLocationActor West;
	UPROPERTY()
	AClawMachineLocationActor East;

	UPROPERTY()
	bool IsNorthValid;
	UPROPERTY()
	bool IsSouthValid;
	UPROPERTY()
	bool IsWestValid;
	UPROPERTY()
	bool IsEastValid;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		if(North != nullptr)
		{
			IsNorthValid = true;
		}
		if(South != nullptr)
		{
			IsSouthValid = true;
		}
		if(West != nullptr)
		{
			IsWestValid = true;
		}
		if(East != nullptr)
		{
			IsEastValid = true;
		}
    }
}

