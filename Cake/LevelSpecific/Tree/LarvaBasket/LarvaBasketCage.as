import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketBall;

import void LarvaBasketEnterCage(AHazePlayerCharacter Player, ALarvaBasketCage Cage) from 'Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent';

class ALarvaBasketCage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UInteractionComponent Interaction;

	UPROPERTY(DefaultComponent)
	USceneComponent AttachComp;

	UPROPERTY(EditDefaultsOnly, Category = "Basket")
	TSubclassOf<ALarvaBasketBall> BallClass;

	TArray<ALarvaBasketBall> BallPool;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnActivated.AddUFunction(this, n"HandleInteraction");

		// Spawn up a buncha balls
		for(int i=0; i<10; ++i)
		{
			auto Ball = Cast<ALarvaBasketBall>(SpawnActor(BallClass, bDeferredSpawn = true, Level = GetLevel()));
			Ball.MakeNetworked(this, i);

			FinishSpawningActor(Ball);
			BallPool.Add(Ball);
		}
	}

	void SetPlayerOwner(AHazePlayerCharacter Player)
	{
		for(auto Ball : BallPool)
			Ball.PlayerOwner = Player;
	}

	UFUNCTION()
	void HandleInteraction(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		LarvaBasketEnterCage(Player, this);
	}

	ALarvaBasketBall GetAvailableBall()
	{
		for(auto Ball : BallPool)
		{
			if (Ball.bIsActive)
				continue;

			return Ball;
		}

		// Force-grab the first one...
		return BallPool[0];
	}
}