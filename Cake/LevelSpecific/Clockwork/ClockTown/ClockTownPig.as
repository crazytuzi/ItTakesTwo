import Vino.Pickups.PickupActor;

class AClockTownPig : APickupActor
{
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000.f;
}