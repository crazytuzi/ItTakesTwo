import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardRocket.CourtyardRocket;

class ACourtyardRocketPump : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundCallbackComp;

	UPROPERTY()
	ACourtyardRocket RocketToLaunch;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundCallbackComp.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		if (RocketToLaunch != nullptr)
			RocketToLaunch.ActivateRocket();
	}
}