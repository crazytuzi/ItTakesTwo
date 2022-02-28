import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.ExitSoilCapability;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;


void TriggerExitShapeBeginPlay()
{
	TArray<AActor> ExitShapes = TArray<AActor>();
	Gameplay::GetAllActorsOfClass(ASneakyBushBlockExitShape::StaticClass(), ExitShapes);
	for(int i = 0; i < ExitShapes.Num(); ++i)
	{
		auto ExitShape = Cast<ASneakyBushBlockExitShape>(ExitShapes[i]);
		ExitShape.TriggerBeginPlay();
	}
}

// This volume will block the player from exiting the bush
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Replication")
class ASneakyBushBlockExitShape : AVolume
{
	UPROPERTY()
	FTutorialPrompt showCancelText;
	default showCancelText.Action = ActionNames::Cancel;
	default showCancelText.MaximumDuration = -1;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
	{
		auto Bush = Cast<ASneakyBush>(OtherActor);
		if(Bush != nullptr && Bush.HasControl())
		{
			// We only need to network this if we care abount the gui
			auto PlantsComponent = UControllablePlantsComponent::Get(Game::GetCody());
			if(PlantsComponent != nullptr)
			{
				PlantsComponent.bCanExitSoil = true;
				PlantsComponent.ExitTutorial = showCancelText;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
	{
		auto Bush = Cast<ASneakyBush>(OtherActor);
		if(Bush != nullptr && Bush.HasControl())
		{
			// We only need to network this if we care abount the gui
			auto PlantsComponent = UControllablePlantsComponent::Get(Game::GetCody());
			if(PlantsComponent != nullptr)
			{
				PlantsComponent.bCanExitSoil = false;
			}
		}
	}

	void TriggerBeginPlay()
	{
		TArray<AActor> OverlappingActors;
		GetOverlappingActors(OverlappingActors, ASneakyBush::StaticClass());
		for(AActor OverlappingActor : OverlappingActors)
		{
			ActorBeginOverlap(OverlappingActor);
		}
	}
}