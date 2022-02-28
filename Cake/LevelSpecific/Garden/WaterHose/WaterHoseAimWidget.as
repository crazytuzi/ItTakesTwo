

UCLASS(Abstract)
class UWaterHoseAimWidget : UHazeUserWidget
{
	UPROPERTY()
	bool bHasAutoAimTarget = false;

	UPROPERTY()
	FVector AutoAimTargetWorldLocation;

	UFUNCTION(BlueprintEvent)
	void OnAimStarted()
	{

	}
}

