
enum EContextIndicatorIcon
{
	None,
	Magnet_Push,
	Magnet_Pull,
	Magnet_PushPlayer,
	Magnet_PullPlayer,
}


class UInteractionContextualWidget : UHazeUserWidget
{
	UPROPERTY()
	FName BindingName = NAME_None;

	UPROPERTY()
	EContextIndicatorIcon CurrentType = EContextIndicatorIcon::None;

	UFUNCTION()
	void SetBinding(FName Binding)
	{
		if(Binding != BindingName)
		{
			BindingName = Binding;
			OnBindingChanged();
		}	
	}

	UFUNCTION()
	void SetContextIcon(EContextIndicatorIcon NewIcon)
	{
		if(CurrentType != NewIcon)
		{
			CurrentType = NewIcon;
			OnContextIconChanged();
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnContextIconChanged()
	{
		// Implement i BP
	}

	UFUNCTION(BlueprintEvent)
	void OnBindingChanged()
	{
		// Implement i BP
	}
};