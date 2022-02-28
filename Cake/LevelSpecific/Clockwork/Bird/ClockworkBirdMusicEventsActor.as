import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;

event void FClockworkBirdMusicEvent();

class AClockworkBirdMusicEventsActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY()
	FClockworkBirdMusicEvent AnyPlayerStartedFlying;
	UPROPERTY()
	FClockworkBirdMusicEvent NoPlayersFlying;
	UPROPERTY()
	FClockworkBirdMusicEvent AnyPlayerBombing;
	UPROPERTY()
	FClockworkBirdMusicEvent NoPlayersBombing;

	UPROPERTY()
	TArray<AClockworkBird> Birds;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	private bool bAnyFlying = false;
	private bool bAnyBombing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AClockworkBird Bird : Birds)
		{
			if (Bird != nullptr)
				Bird.OnPlayerMounted.AddUFunction(this, n"OnPlayerMountedBird");
		}
	}

	UFUNCTION()
	private void OnPlayerMountedBird(AHazePlayerCharacter Player)
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bAnyBirdMounted = false;
		bool bNewFlying = false;
		bool bNewBombing = false;

		for (AClockworkBird Bird : Birds)
		{
			if (Bird.ActivePlayer != nullptr)
			{
				bAnyBirdMounted = true;
				if (Bird.bIsFlying)
					bNewFlying = true;
				if (Bird.bIsHoldingBomb)
					bNewBombing = true;
			}
		}

		if (bNewFlying != bAnyFlying)
		{
			bAnyFlying = bNewFlying;
			if (bAnyFlying)
				AnyPlayerStartedFlying.Broadcast();
			else
				NoPlayersFlying.Broadcast();
		}

		if (bNewBombing != bAnyBombing)
		{
			bAnyBombing = bNewBombing;
			if (bAnyBombing)
				AnyPlayerBombing.Broadcast();
			else
				NoPlayersBombing.Broadcast();
		}

		if (!bAnyBirdMounted)
		{
			// Stop ticking when no players are on the birds anymore
			SetActorTickEnabled(false);
		}
	}
};