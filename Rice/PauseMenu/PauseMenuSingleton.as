event void FOnPauseMenuOpened();
event void FOnPauseMenuClosed();

enum EPauseMenuStartSubMenu
{
	Default,
	Options,
}

class UPauseMenuSingleton : UObjectTickable
{
	FOnPauseMenuOpened OnOpened;
	FOnPauseMenuOpened OnClosed;
	FOnPauseMenuOpened OnOptionsOpened;
	FOnPauseMenuOpened OnOptionsClosed;

	UWidget ChatWidget;
	UWidget UpsellWidget;

	// What sub menu to start with next time pause menu is opened
	EPauseMenuStartSubMenu StartSubMenu = EPauseMenuStartSubMenu::Default;

	// Which options menu entry should be selected next time options menu is opened
	FName OptionsMenuSelectedSlot = NAME_None;

	// When we open pause menu, we will open options menu and have given slot selected automatically 
	void PrepareForOptionsMenu(FName SelectedSlot = NAME_None)
	{
		StartSubMenu = EPauseMenuStartSubMenu::Options;
		OptionsMenuSelectedSlot = SelectedSlot;
	}

	void Reset()
	{
		StartSubMenu = EPauseMenuStartSubMenu::Default;
		OptionsMenuSelectedSlot = NAME_None;
	}
};

namespace UPauseMenuSingleton
{
	UPauseMenuSingleton Get()
	{
		return Cast<UPauseMenuSingleton>(Game::GetSingleton(UPauseMenuSingleton::StaticClass()));
	}
};
