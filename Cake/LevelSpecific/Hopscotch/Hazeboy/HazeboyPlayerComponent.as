import Cake.LevelSpecific.Hopscotch.Hazeboy.Hazeboy;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboySettings;

class UHazeboyPlayerComponent : UActorComponent
{
	AHazeboy CurrentDevice;
	UHazeCapabilitySheet CurrentSheet;

	bool bHasCancelled = false;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	TPerPlayer<UAnimSequence> EnterAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	TPerPlayer<UAnimSequence> MHAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	TPerPlayer<UAnimSequence> ExitAnim;
}

void StartUsingHazeboy(AHazePlayerCharacter Player, AHazeboy Device)
{
	Device.InteractedPlayer = Player;
	Player.AddCapabilitySheet(Device.PlayerSheet, EHazeCapabilitySheetPriority::Interaction, Device);

	auto HazeboyComp = UHazeboyPlayerComponent::Get(Player);
	if (HazeboyComp == nullptr)
		return;

	if (Device == nullptr)
		return;

	HazeboyComp.CurrentDevice = Device;
	HazeboyComp.CurrentSheet = Device.PlayerSheet;
	HazeboyComp.bHasCancelled = false;
}

void StopUsingHazeboy(AHazePlayerCharacter Player)
{
	auto HazeboyComp = UHazeboyPlayerComponent::Get(Player);
	if (HazeboyComp == nullptr)
		return;

	// Finally clean up the component and remove the sheet!
	auto Sheet = HazeboyComp.CurrentSheet;
	auto Device = HazeboyComp.CurrentDevice;

	HazeboyComp.CurrentDevice = nullptr;
	HazeboyComp.CurrentSheet = nullptr;

	if (Sheet != nullptr)
		Player.RemoveCapabilitySheet(Sheet, Device);
}