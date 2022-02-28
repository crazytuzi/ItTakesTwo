import Cake.LevelSpecific.SnowGlobe.AxeThrowing.IceAxeActor;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingTarget;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingStartInteraction;

class AAxeThrowingAxeManager : AHazeActor
{
	TArray<AIceAxeActor> AxeArray;

	UPROPERTY(Category = "Setup")
	TSubclassOf<AIceAxeActor> IceAxeClass;

	UPROPERTY(Category = "Setup")
	AAxeThrowingStartInteraction MayStart;
	
	UPROPERTY(Category = "Setup")
	AAxeThrowingStartInteraction CodyStart;

	int SpawnedAxes = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(AxeArray);

		for(AIceAxeActor Axe : AxeArray)
		{
			Axe.MayStart = MayStart;
			Axe.CodyStart = CodyStart;
		}

		// Divvy up the axes between the two players so we never need to worry
		// about conflicting activate/deactivates of axes between players
		auto Players = Game::Players;
		for(int i=0; i<AxeArray.Num(); ++i)
			AxeArray[i].PlayerOwner = Players[i % 2];
	}

	AIceAxeActor GetAvailableAxe(AHazePlayerCharacter Player)
	{
		for(AIceAxeActor Axe : AxeArray)
		{
			if (Axe.PlayerOwner != Player)
				continue;

			if (!Axe.bIsActive)
				return Axe;
		}

		AIceAxeActor NewAxe = Cast<AIceAxeActor>(SpawnActor(IceAxeClass, bDeferredSpawn = true));
		NewAxe.MakeNetworked(this, SpawnedAxes++);
		NewAxe.FinishSpawningActor();

		if (NewAxe != nullptr)
		{
			NewAxe.PlayerOwner = Player;
			NewAxe.MayStart = MayStart;
			NewAxe.CodyStart = CodyStart;
			
			AxeArray.Add(NewAxe);
			return NewAxe;
		}

		return nullptr;
	}

	UFUNCTION()
	void DeactivateAllAxes()
	{
		for (AIceAxeActor Axe : AxeArray)
		{
			if (!Axe.IsActorDisabled())
				Axe.DeactivateAxe();
		}
	}

	UFUNCTION()
	void ResetAllAxes(AIceAxeActor ExceptionAxeOne, AIceAxeActor ExceptionAxeTwo)
	{
		for (AIceAxeActor Axe : AxeArray)
		{
			if (Axe.bIsActive)
			{
				if (Axe != ExceptionAxeOne && Axe != ExceptionAxeTwo)
					Axe.DeactivateAxe();
			}

		}
	}
}