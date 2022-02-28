
class UTrackRunnerPlayerComponent : UActorComponent
{
	UPROPERTY()
	bool bDashLeft = false;
	UPROPERTY()
	bool bDashRight = false;
	UPROPERTY()
	bool bJump = false;
	UPROPERTY()
	bool bRun = false;
	UPROPERTY()
	bool bImpact = false;
	UPROPERTY()
	bool bStartUp = true;

	UFUNCTION(BlueprintOverride)
    void BeginPlay() {}
}


