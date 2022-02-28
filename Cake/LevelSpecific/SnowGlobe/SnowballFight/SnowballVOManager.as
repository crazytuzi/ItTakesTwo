import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballPickupInteraction;

class ASnowballVOManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(Category = "Setup")
	TArray<ASnowballPickupInteraction> SnowballInteractions;

	bool bPlayedApproach;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ASnowballPickupInteraction PileInteraction : SnowballInteractions)
		{
			PileInteraction.PlayerLookAtTrigger.OnBarkTriggered.AddUFunction(this, n"ApproachBarkTriggered");
		}
	}

	UFUNCTION()
	void ApproachBarkTriggered(AHazePlayerCharacter Player)
	{
		if (bPlayedApproach)
			return;

		bPlayedApproach = true;

		for (ASnowballPickupInteraction PileInteraction : SnowballInteractions)
		{
			PileInteraction.PlayerLookAtTrigger.DisableActor(this);
		}	
	}
}