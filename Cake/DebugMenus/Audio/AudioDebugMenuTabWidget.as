class UAudioDebugMenuTabWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	FText TabDisplayName;

	UFUNCTION(BlueprintEvent)
	UScrollBox GetSettingsScrollBox()
	{
		return nullptr;
	}

}