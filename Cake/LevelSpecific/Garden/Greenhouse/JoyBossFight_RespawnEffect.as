import Vino.PlayerHealth.FadedPlayerRespawnEffect;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

class UJoyBossFight_RespawnEffect : UFadedPlayerRespawnEffect
{
	void TeleportToRespawnLocation(FPlayerRespawnEvent Event)
	{
        if(Player != nullptr && Player.IsCody())
		{
			UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Player);
			if(PlantsComp != nullptr && PlantsComp.CurrentPlant != nullptr)
			{
				PlantsComp.CurrentPlant.TeleportActor(
					Location = Event.GetWorldLocation(),
					Rotation = Event.Rotation
				);

				return;
			}
		}

		Super::TeleportToRespawnLocation(Event);
	}
}
