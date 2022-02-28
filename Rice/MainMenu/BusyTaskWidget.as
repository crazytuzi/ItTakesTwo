import Rice.MainMenu.MainMenu;

class UBusyTaskWidget : UMainMenuStateWidget
{
	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (MainMenu.IsOwnerInput(Event))
		{
			// Try to cancel the busy task when pressing cancel
			if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
			{
				if (MainMenu.CanCancelBusyTask())
					MainMenu.CancelBusyTask();
				return FEventReply::Handled();
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride)
	UWidget GetInitialFocusWidget()
	{
		return this;
	}
};