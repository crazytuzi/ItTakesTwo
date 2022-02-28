import Peanuts.ButtonMash.ButtonMashComponent;
import Peanuts.ButtonMash.ButtonMashHandleBase;

namespace ButtonMashTags
{
	const FName ButtonMash = n"ButtonMash";
}

UButtonMashHandleBase CreateButtonMashHandle(
	AHazePlayerCharacter Player,
	UClass HandleClass)
{
	// No player specified
	if (!ensure(Player != nullptr, "You have to specify a player for the button mash"))
		return nullptr;

	UButtonMashHandleBase Handle = Cast<UButtonMashHandleBase>(NewObject(Player, HandleClass));
	Handle.Player = Player;
	Handle.bIsValid = true;

	return Handle;
}

void StartButtonMashInternal(UButtonMashHandleBase Handle)
{
	// No player specified
	if (!ensure(Handle.bIsValid, "Trying to start a button mash with an invalid handle"))
		return;

	UButtonMashComponent Component = UButtonMashComponent::Get(Handle.Player);
	Component.ResetMashRate();
	Component.StartButtonMash(Handle);

	Handle.StartUp();
}

// Resets all values of the mash, returning to a vanilla-state
UFUNCTION(Category = "Button Mash")
void ResetButtonMash(UButtonMashHandleBase Handle)
{
	UButtonMashComponent Component = UButtonMashComponent::Get(Handle.Player);
	if (!ensure(Handle.bIsValid && Component.CurrentButtonMash == Handle))
		return;

	Component.ResetMashRate();
	Handle.Reset();
}

UFUNCTION(Category = "Button Mash")
void StopButtonMash(UButtonMashHandleBase MashHandle)
{
	if (!ensure(MashHandle.Player != nullptr))
		return;

	UButtonMashComponent Component = UButtonMashComponent::Get(MashHandle.Player);

	// Only end if this is the current buttonmash
	if (Component.CurrentButtonMash == MashHandle)
		Component.CurrentButtonMash = nullptr;

	MashHandle.bIsValid = false;
	MashHandle.MashRateControlSide = 0.f;
	MashHandle.CleanUp();
}