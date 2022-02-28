import Rice.MainMenu.MainMenu;
import Rice.OptionsMenu.OptionsMenu;

class UMainOptionsMenu : UMainMenuStateWidget
{
	UFUNCTION(BlueprintEvent)
	UOptionsMenu GetOptionsMenu() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Show(bool bSnap)
	{
		Super::Show(bSnap);

		OptionsMenu.Identity = MainMenu.OwnerIdentity;
		OptionsMenu.OnClosed.BindUFunction(this, n"OnOptionsMenuClosed");
		OptionsMenu.ConstructGameSettings();

		if(!OptionsMenu.bCanPlayConfirmationOnOpenSound)
			GetAudioManager().UI_OptionsMenuOpen();

		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_OptionsMenu_IsOpen", 1.f);
	}

	UFUNCTION()
	void OnOptionsMenuClosed()
	{
		MainMenu.ReturnToMainMenu(bSnap = true);
	}

	UFUNCTION(BlueprintOverride)
	UWidget GetInitialFocusWidget()
	{
		return OptionsMenu.GetInitialFocus();
	}
};