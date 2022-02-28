import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

UCLASS(Abstract)
class ATimeControlBreakingPot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent LeftPotHalf;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent RightPotHalf;

	UPROPERTY(DefaultComponent, Attach = LeftPotHalf)
	UTimeControlActorComponent TimeControlComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;
}