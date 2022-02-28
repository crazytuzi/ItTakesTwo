
class UCancelPromptWidget : UHazeUserWidget
{
	UPROPERTY()
	FText DefaultCancelText;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText CancelText;

	UPROPERTY(BlueprintReadOnly)
	bool bIsAllowedToCancel = true;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintEvent)
    void OnCancelPressed()
    {
    }

	UFUNCTION(BlueprintEvent)
	void Update()
	{
	}
};