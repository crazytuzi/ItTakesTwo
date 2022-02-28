
delegate void FOnKeyBindInputSelectedSignature(FKey NewKey);
event void FOnKeyBindInputSelected(FKey NewKey);

class UGameSettingsKeyBindOverlayWidget : UHazeUserWidget
{
	UPROPERTY()
	FOnKeyBindInputSelected OnInputSelected;

	UFUNCTION(BlueprintOverride)
	FEventReply OnPreviewKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnPreviewMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		OnInputSelected.Broadcast(Event.Key);
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		OnInputSelected.Broadcast(Event.GetEffectingButton());
		return FEventReply::Handled();
	}

}