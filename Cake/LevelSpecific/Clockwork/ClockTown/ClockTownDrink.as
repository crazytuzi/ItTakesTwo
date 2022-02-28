import Vino.Pickups.PickupActor;

class AClockTownDrink : APickupActor
{
	UFUNCTION()
	void EnableInteraction()
	{
		InteractionComponent.Enable(n"Held");
	}

	UFUNCTION()
	void DisableInteraction()
	{
		InteractionComponent.Disable(n"Held");
	}
}