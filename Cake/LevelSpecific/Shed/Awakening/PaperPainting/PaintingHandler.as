import Cake.Environment.GPUSimulations.PaperPainting;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

class APaintingHandler : AStaticMeshActor
{

	UPROPERTY()
	APaperPainting Actor;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		Actor.GroundPound(Player, true, Player.ActorLocation, 0);
	}
}