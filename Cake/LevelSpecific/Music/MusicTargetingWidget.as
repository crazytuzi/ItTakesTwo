
UCLASS(Abstract)
class UMusicTargetingWidget : UHazeUserWidget
{
	private FVector _TargetLocation;
	private bool bHasTarget = false;

	UFUNCTION(BlueprintPure)
	bool HasTarget() const { return bHasTarget; }

	UFUNCTION(BlueprintPure)
	FVector GetTargetLocation() const
	{
		if(!bHasTarget)
			return FVector(0.5f, 0.5f, 0.0f);

		return _TargetLocation;
	}

	void SetHasTarget(bool bValue) 
	{ 
		const bool bOldHasTarget = bHasTarget;
		bHasTarget = bValue;

		if(!bOldHasTarget && bHasTarget)
		{
			BP_OnTargetFound();
		}
		else if(bOldHasTarget && !bHasTarget)
		{
			BP_OnTargetLost();
		}
	}

	void SetTargetLocation(FVector InTargetLocation) { _TargetLocation = InTargetLocation; }

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Target Found"))
	void BP_OnTargetFound() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Target Lost"))
	void BP_OnTargetLost() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Update Widget Offset"))
	void BP_OnUpdateWidgetOffset(FVector2D NewWidgetOffset) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Start Aiming"))
	void BP_OnStartAiming() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Stop Aiming"))
	void BP_OnStopAiming() {}
}
