import Vino.Checkpoints.Checkpoint;
import Peanuts.Triggers.PlayerTrigger;
import Peanuts.Fades.FadeStatics;
import Vino.PlayerHealth.FadedPlayerRespawnEffect;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsStatics;

class AMoleStealthCheckpoint : ACheckpoint
{
	UPROPERTY()
	ASubmersibleSoilSneakyBush LinkedSoil;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnRespawnAtCheckpoint.AddUFunction(this, n"OnRespawn");		
	}

    void TeleportPlayerToCheckpoint(AHazePlayerCharacter Player) override
    {
    	Super::TeleportPlayerToCheckpoint(Player);
		MakeCodyIntoBush(Player);
    }

	UFUNCTION(NotBlueprintCallable)
	void OnRespawn(AHazePlayerCharacter RespawningPlayer)
	{
		MakeCodyIntoBush(RespawningPlayer);
	}

	void MakeCodyIntoBush(AHazePlayerCharacter Player)
	{
		UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Game::GetCody());
		devEnsure(PlantsComp.CurrentPlant == nullptr);

		if(Player.IsCody() && LinkedSoil != nullptr)
		{
			ControllablePlantsStatics::CodyBecomePlant_Local(LinkedSoil.SoilComp.PlantClass, Player.GetActorTransform(), LinkedSoil.SoilComp);
		}
	}
}