import Rice.OptionsMenu.OptionsMenu;

class UPauseOptionsMenu : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	UOptionsMenu GetOptionsMenu() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry Geom, FFocusEvent Event)
	{
		return FEventReply::Handled().SetUserFocus(OptionsMenu.InitialFocus);
	}
}
