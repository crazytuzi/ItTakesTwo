import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonSwiveldoor;

UFUNCTION()
void SetNewSwivelDoor(AHazePlayerCharacter TargetPlayer, AHopscotchDungeonSwivelDoor NewSwivelDoor)
{
	if (!TargetPlayer.HasControl())
		return;

	UHopscotchDungeonSwivelDoorComponent Comp = UHopscotchDungeonSwivelDoorComponent::Get(TargetPlayer);

	if (Comp != nullptr)
		Comp.SwivelDoor = NewSwivelDoor;
}

class UHopscotchDungeonSwivelDoorComponent : UActorComponent
{
	AHopscotchDungeonSwivelDoor SwivelDoor;
}