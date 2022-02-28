import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.PlayerButtonMashIntoTomatoCapability;


namespace TomatoStatics
{
	// Start a button mash wich will turn Cody into the tomato-class of choice whenever completed.
	UFUNCTION()
	void StartTomatoButtonMash(TSubclassOf<ATomato> TomatoClass)
	{
		UPlayerButtonMashIntoTomatoComponent TomatoMash = UPlayerButtonMashIntoTomatoComponent::Get(Game::GetCody());
		if(TomatoMash != nullptr)
		{
			TomatoMash.SetTargetTomatoClass(TomatoClass);
		}
	}

	UTomatoSettings GetTomatoSettingsFromPlayer(AHazePlayerCharacter Player)
	{
		UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Player);

		if(PlantsComp != nullptr && PlantsComp.CurrentPlant != nullptr)
		{
			UTomatoSettings TomatoSettings = UTomatoSettings::GetSettings(PlantsComp.CurrentPlant);
			return TomatoSettings;
		}

		return nullptr;
	}
}
