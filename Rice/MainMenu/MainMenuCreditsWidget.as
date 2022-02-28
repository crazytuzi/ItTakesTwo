import Rice.MainMenu.MainMenu;
import Rice.MainMenu.CreditsWidget;

class UMainMenuCreditsWidget : UMainMenuStateWidget
{
	UPROPERTY()
	UCreditsWidget CreditsWidget;

	UFUNCTION(BlueprintOverride)
	void Show(bool bSnap)
	{
		Super::Show(bSnap);

		CreditsWidget.OnCreditsFinishedPlaying.Clear();
		CreditsWidget.OnCreditsFinishedPlaying.AddUFunction(this, n"OnCreditsFinished");
		CreditsWidget.PlayCreditsFromStart();

		GetAudioManager().UI_OnSelectionConfirmed();
		AkGameplay::SetState(n"MStg_UI_Menu", n"Mstt_US_Menu_Credits");
	}

	UFUNCTION()
	void OnCreditsFinished()
	{
		MainMenu.ReturnToMainMenu(bSnap = false);
		AkGameplay::SetState(n"MStg_UI_Menu", n"Mstt_US_Menu_UXR");
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (MainMenu.IsOwnerInput(Event))
		{
			// Try to cancel the busy task when pressing cancel
			if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
			{
				MainMenu.ReturnToMainMenu(bSnap = false);
				GetAudioManager().UI_OnSelectionCancel();				
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