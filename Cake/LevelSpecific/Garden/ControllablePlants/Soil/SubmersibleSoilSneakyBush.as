import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;

class ASubmersibleSoilSneakyBush : ASubmersibleSoil
{
	UPROPERTY(EditInstanceOnly, Category = "Soil")
	APaintablePlane PaintablePlain;
}

class ASubmersibleSoilSneakyBushShape : AVolume
{
	UPROPERTY()
	ASubmersibleSoilSneakyBush LinkedSoil;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);					
   	
		TArray<AActor> OverlappingPlayers;
		GetOverlappingActors(OverlappingPlayers, AHazePlayerCharacter::StaticClass());
		for(int i = 0; i < OverlappingPlayers.Num(); ++i)
		{
			ActorBeginOverlap(OverlappingPlayers[i]);
		}
	}

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
	{
		if(LinkedSoil != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player != nullptr && Player.HasControl() && Player.IsCody())
			{
				NetSetCodyInShape(true);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
	{
		if(LinkedSoil != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player != nullptr && Player.HasControl() && Player.IsCody())
			{
				NetSetCodyInShape(false);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetCodyInShape(bool bStatus)
	{
		auto Cody = Game::GetCody();
		if(bStatus)
		{
			auto PlantComp = UControllablePlantsComponent::Get(Cody);
			if(PlantComp != nullptr)
			{
				PlantComp.SetLinkedActivatingSoil(LinkedSoil.SoilComp);
				Capability::AddPlayerCapabilityRequest(n"GroundPoundAndBecomeSneakyBushCapability", EHazeSelectPlayer::Cody);
			}

			auto ManagerComponent = UMoleStealthPlayerComponent::Get(Cody);
			ManagerComponent.IsInsideGroundPoundableAreaCount++;
		}
		else
		{
			auto PlantComp = UControllablePlantsComponent::Get(Cody);
			if(PlantComp != nullptr)
			{				
				PlantComp.ClearLinkedActiveSoil();
				Capability::RemovePlayerCapabilityRequest(n"GroundPoundAndBecomeSneakyBushCapability", EHazeSelectPlayer::Cody);
			}

			
			auto ManagerComponent = UMoleStealthPlayerComponent::Get(Cody);
			ManagerComponent.IsInsideGroundPoundableAreaCount--;
		}
	}
}
