import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;

class ASubmersibleSoilTomato : ASubmersibleSoil
{
	UFUNCTION()
	void ForceSpawnTomatoAtSoilLocation()
	{
		auto Cody = Game::GetCody();
		if(Cody.HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddVector(n"SpawnLocation", GetActorLocation());
			UHazeCrumbComponent::Get(Cody).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ForceSpawnTomatoAtLocation"), CrumbParams);
		}
	}

	UFUNCTION()
	void ForceSpawnTomatoAtCodyLocation()
	{
		auto Cody = Game::GetCody();
		if(Cody.HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddVector(n"SpawnLocation", Cody.GetActorLocation());
			UHazeCrumbComponent::Get(Cody).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ForceSpawnTomatoAtLocation"), CrumbParams);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_ForceSpawnTomatoAtLocation(const FHazeDelegateCrumbData& CrumbData)
	{
		auto Cody = Game::GetCody();
		Cody.TriggerMovementTransition(this);
		Cody.SetActorLocation(CrumbData.GetVector(n"SpawnLocation"));
		HideWidget();
		ActivateSubmersibleSoilComponent(SoilComp, Game::GetCody());
	}
}
