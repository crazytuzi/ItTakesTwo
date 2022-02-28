import Vino.AI.Scenepoints.ScenepointComponent;

UCLASS(Abstract)
class AScenepointActorBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Engine/EngineResources/AICON-Green.AICON-Green");

	UFUNCTION()
	UScenepointComponent GetScenepoint()
	{
		return nullptr;
	};
}

class AScenepointActor : AScenepointActorBase
{
	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;
	default ArrowComponent.SetRelativeLocation(FVector(20.f, 0.f, 0.f));
	default ArrowComponent.ArrowSize = 0.7f;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	UScenepointComponent ScenepointComponent;

	UFUNCTION()
	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}
