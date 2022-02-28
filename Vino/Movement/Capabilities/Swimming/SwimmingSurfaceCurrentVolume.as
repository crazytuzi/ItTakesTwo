import Peanuts.Triggers.PlayerTrigger;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class ASwimmingSurfaceCurrentVolume : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UArrowComponent CurrentDirection;

	// Added as acceleration in the direction of the direction arrow
	UPROPERTY(Category = Settings)
	float CurrentStrength = 1000.f;

	TPerPlayer<USnowGlobeSwimmingComponent> SwimmingComps;

	void EnterTrigger(AActor Actor) override
    {
		APlayerTrigger::EnterTrigger(Actor);

		USnowGlobeSwimmingComponent SwimmingComp = USnowGlobeSwimmingComponent::GetOrCreate(Actor);
		if (SwimmingComp == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		SwimmingComps[Player] = SwimmingComp;
    }

	void LeaveTrigger(AActor Actor) override
    {
		APlayerTrigger::LeaveTrigger(Actor);

		USnowGlobeSwimmingComponent SwimmingComp = USnowGlobeSwimmingComponent::GetOrCreate(Actor);
		if (SwimmingComp == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		SwimmingComps[Player] = nullptr;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (SwimmingComps[Player] == nullptr)
				continue;
			if (!SwimmingComps[Player].bIsInWater)
				continue;

			FVector CurrentAcceleration = CurrentDirection.ForwardVector * CurrentStrength * DeltaTime;
			Player.AddImpulse(CurrentAcceleration);
		}
	}
}