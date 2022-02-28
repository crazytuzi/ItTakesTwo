import Cake.FlyingMachine.Pilot.FlyingMachinePilotComponent;

UFUNCTION(Category = "Vehicles|FlyingMachine")
void SetFlyingMachinePilotTargetCamera(AHazePlayerCharacter Player, UHazeCameraComponent Camera)
{
	auto PilotComp = UFlyingMachinePilotComponent::GetOrCreate(Player);
	PilotComp.TargetCamera = Camera;
}