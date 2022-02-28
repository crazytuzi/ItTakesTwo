import Cake.LevelSpecific.Hopscotch.HopscotchElevator;

UFUNCTION()
void ActivateHopscotchElevator(AHazePlayerCharacter TargetPlayer, AHopscotchElevator NewElevator, USceneComponent NewAttachComp)
{
	UHopscotchElevatorComponent Comp = UHopscotchElevatorComponent::GetOrCreate(TargetPlayer);

	if (Comp != nullptr)
	{
		Comp.Elevator = NewElevator;
		Comp.AttachComp = NewAttachComp;
	}
}

UFUNCTION()
void DeactivateHopscotchElevator(AHazePlayerCharacter TargetPlayer)
{
	UHopscotchElevatorComponent Comp = UHopscotchElevatorComponent::GetOrCreate(TargetPlayer);

	if (Comp != nullptr)
	{
		Comp.Elevator = nullptr;
		Comp.AttachComp = nullptr;
	}
}

class UHopscotchElevatorComponent : UActorComponent
{
	USceneComponent AttachComp;
	AHopscotchElevator Elevator;
}