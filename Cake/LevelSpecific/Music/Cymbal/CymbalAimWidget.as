
UCLASS(abstract)
class UCymbalAimWidget : UHazeUserWidget
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

	void SetHasTarget(bool bValue) { bHasTarget = bValue; }
	void SetTargetLocation(FVector InTargetLocation) { _TargetLocation = InTargetLocation; }

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Update Relative Offset"))
	void BP_OnUpdateRelativeOffset(FVector2D RelativeOffset) {}
}
