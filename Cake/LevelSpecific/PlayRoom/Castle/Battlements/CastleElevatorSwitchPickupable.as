import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleElevatorSwitch;
import Vino.Pickups.PickupActor;

class ACastleElevatorSwitchPickupable : APickupActor
{
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
}