import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;
import Peanuts.Triggers.BothPlayerTrigger;

class AWindWalkDoublePullStartTrigger : ABothPlayerTrigger
{
	UPROPERTY()
	AWindWalkDoublePullActor WindWalkDoublePull;
	UDoublePullComponent DoublePullComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoublePullComponent = UDoublePullComponent::Get(WindWalkDoublePull);

		// Bind trigger delegates
		OnBothPlayersInside.AddUFunction(this, n"OnPlayersEntered");
		OnStopBothPlayersInside.AddUFunction(this, n"OnPlayersExited");
		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayersEntered()
	{
		if(!DoublePullComponent.AreBothPlayersInteracting())
			return;

		WindWalkDoublePull.bIsInStartZone = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayersExited()
	{
		WindWalkDoublePull.bIsInStartZone = false;
	}
}
