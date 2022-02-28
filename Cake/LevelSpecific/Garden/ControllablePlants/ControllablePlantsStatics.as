import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

namespace ControllablePlantsStatics
{
	UFUNCTION()
	void CodyBecomePlant(TSubclassOf<AControllablePlant> PlantClass)
	{
		UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Game::GetCody());

		if(PlantsComp != nullptr)
		{
			PlantsComp.ActivatePlant(PlantClass);
		}
	}

	UFUNCTION()
	void CodyBecomePlant_Local(TSubclassOf<AControllablePlant> PlantClass, FTransform ActivationTransform, USubmersibleSoilComponent ActivatingSoil = nullptr)
	{
		UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Game::GetCody());

		if(PlantsComp != nullptr)
		{
			PlantsComp.ActivatePlant_Local(PlantClass, ActivationTransform, ActivatingSoil);
		}
	}

	UFUNCTION()
	void StopControllingPlant()
	{
		UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Game::GetCody());

		if(PlantsComp != nullptr && PlantsComp.CurrentPlant != nullptr)
		{
			PlantsComp.CurrentPlant.UnPossessPlant();
		}
	}
}
