
delegate void FOnPendingChangesOverlayClosed(bool DiscardChanges);

class UOptionsMenuPendingChangesOverlay : UHazeUserWidget
{
	FOnPendingChangesOverlayClosed OnOverlayClosed;

	UFUNCTION()
	void DiscardChanges()
	{
		OnOverlayClosed.ExecuteIfBound(true);
	}

	UFUNCTION()
	void KeepChanges()
	{
		OnOverlayClosed.ExecuteIfBound(false);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		// Don't let keys through, this is a modal dialog
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		if (Event.Key == EKeys::Virtual_Back || Event.Key == EKeys::Escape || Event.Key == EKeys::BackSpace)
		{
			KeepChanges();
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Virtual_Accept || Event.Key == EKeys::Enter)
		{
			DiscardChanges();
			return FEventReply::Handled();
		}
		
		// Don't let keys through, this is a modal dialog
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		// Don't let clicks through, this is a modal dialog
		return FEventReply::Handled();
	 }

}