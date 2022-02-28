import Cake.LevelSpecific.Hopscotch.FidgetspinnerActor;
import Cake.LevelSpecific.Hopscotch.BallFallTube;
class UBallPitCameraVolumeCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		TArray<AActor> Actors;
		Player.GetAttachedActors(Actors);

		bool bHasFidget = false;
		bool bHasPlayerStoryBark = false;
		for (auto Actor : Actors)
		{
			AFidgetSpinnerActor Fidget = Cast<AFidgetSpinnerActor>(Actor);
			if (Fidget != nullptr)
			{
				bHasFidget = true;
				if (Player == Game::GetMay())
					bHasPlayerStoryBark = Fidget.bHasPlayerStoryBark;
			}
		}

		if (!bHasFidget || !bHasPlayerStoryBark)
			return false;

		TArray<ABallFallTube> BallFallArray;
		GetAllActorsOfClass(BallFallArray);

		bool bNoValvesDone = false;
		for (auto BallFall : BallFallArray)
		{
			if (BallFall.bMainBallFall)
			{
				if (BallFall.BallFallIntensity == 3)
					bNoValvesDone = true;
			}
		}

		if (!bNoValvesDone)
			return false;
		
		return true;
	}
}