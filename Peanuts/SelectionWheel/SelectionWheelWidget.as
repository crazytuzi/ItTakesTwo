struct FSelectionWheelSegmentData
{
	UPROPERTY()
	UTexture2D Icon;

	UPROPERTY()
	FText Description;
}

UCLASS(Abstract)
class USelectionWheelWidget : UHazeUserWidget
{
	UPROPERTY(Category = "SelectionWheel")
	int SelectedIndex = 0;

	UFUNCTION(BlueprintEvent)
	void AddSegment(FSelectionWheelSegmentData Data)
	{
	}

	UFUNCTION(BlueprintEvent)
	void PlaySelectAnimationAndRemove(int Index)
	{
	}
}