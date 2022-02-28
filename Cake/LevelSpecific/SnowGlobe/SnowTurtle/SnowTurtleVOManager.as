import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleMother;

class ASnowTurtleVOManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<ASnowTurtleBaby> SnowTurtleArray;

	UPROPERTY(Category = "Setup")
	ASnowTurtleMother SnowTurtleMother;

	UPROPERTY(Category = "Setup")
	ASnowTurtleEventManager SnowTurtleEventManager;

	UPROPERTY(Category = "Setup")
	float VORange = 12000.f;

	UPROPERTY(Category = "Setup")
	UFoghornVOBankDataAssetBase VOLevelBank;

	TPerPlayer<bool> bPlayedVO;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ASnowTurtleBaby Turtle : SnowTurtleArray)
		{
			Turtle.LookAtVOTrigger.OnBarkTriggered.AddUFunction(this, n"OnApproachVOPlayed");
			Turtle.OnTurtleArrivedToNest.AddUFunction(this, n"CheckAndPlayTurtleArrived");
		}

		SnowTurtleEventManager.OnFinishTurtleQuest.AddUFunction(this, n"CheckAndPlayComplete");
	}

	UFUNCTION()
	void OnApproachVOPlayed(AHazePlayerCharacter Player)
	{
		for (ASnowTurtleBaby Turtle : SnowTurtleArray)
			Turtle.LookAtVOTrigger.DisableActor(this);	
	}

	UFUNCTION()
	void CheckAndPlayTurtleArrived()
	{
		float MayDist = Game::May.GetDistanceTo(SnowTurtleMother);
		float CodyDist = Game::Cody.GetDistanceTo(SnowTurtleMother);

		if (!bPlayedVO[0])
		{
			if (MayDist <= VORange)
			{
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesFirstTurtleBackMay");
				bPlayedVO[0] = true;
			}
		}
		else if (!bPlayedVO[1])
		{
			if (CodyDist <= VORange)
			{
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesFirstTurtleBackCody");
				bPlayedVO[1] = true;
			}
		}
		else if (!bPlayedVO[0] && !bPlayedVO[1])
		{
			if (MayDist <= VORange && MayDist < CodyDist)
			{
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesFirstTurtleBackMay");
				bPlayedVO[0] = true;
			}
			else if (CodyDist <= VORange && CodyDist < MayDist)
			{
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesFirstTurtleBackCody");
				bPlayedVO[1] = true;
			}
			else if (CodyDist < VORange && MayDist < VORange)
			{
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesFirstTurtleBackMay");
				bPlayedVO[0] = true;
			}
		}
	}

	UFUNCTION()
	void CheckAndPlayComplete()
	{
		float MayDist = Game::May.GetDistanceTo(SnowTurtleMother);
		float CodyDist = Game::Cody.GetDistanceTo(SnowTurtleMother);

		if (MayDist <= VORange && MayDist < CodyDist)
		{
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesOnCompletionMay");
			bPlayedVO[0] = true;
		}
		else if (CodyDist <= VORange && CodyDist < MayDist)
		{
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesOnCompletionCody");
			bPlayedVO[1] = true;
		}
		else if (CodyDist < VORange && MayDist < VORange)
		{
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowglobeTownSnowTurtlesOnCompletionCody");
			bPlayedVO[0] = true;
		}
	}
}