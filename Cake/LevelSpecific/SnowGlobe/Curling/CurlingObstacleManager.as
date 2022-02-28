import Cake.LevelSpecific.SnowGlobe.Curling.CurlingObstacleHolder;
import Cake.LevelSpecific.SnowGlobe.Curling.StaticsCurling;

struct FCurlingObstacleGroup
{
	UPROPERTY()
	TArray<ACurlingObstacle> Obstacles;
}

class ACurlingObstacleManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<FCurlingObstacleGroup> ObstacleGroups;

	UPROPERTY(Category = "Setup")
	TArray<ACurlingObstacleHolder> Holders;

	UFUNCTION(CallInEditor)
	void CopyHolders()
	{
		ObstacleGroups.Empty();
		for(auto Holder : Holders)
		{
			FCurlingObstacleGroup Group;
			for(auto Obstacle : Holder.CurlingObstacleArray)
				Group.Obstacles.Add(Obstacle);

			ObstacleGroups.Add(Group);
		}
	}

	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ObstaclesChange;

	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> PlayerCamShake;

	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect PlayerFeedbackForce;

	float MinDist = 8500.f;

	int ChosenIndex;

	UFUNCTION()
	void ActivateObstacles()
	{
		ChosenIndex = (ChosenIndex + 1) % ObstacleGroups.Num();

		PlayerFeedback(Game::May);
		PlayerFeedback(Game::Cody);

		NetActivatedObstacles(ChosenIndex); 
	}

	UFUNCTION()
	void PlayerFeedback(AHazePlayerCharacter Player)
	{
		float PlayerDist = (Player.ActorLocation - ActorLocation).Size();

		if (PlayerDist <= MinDist)
		{
			Player.PlayCameraShake(PlayerCamShake);
			Player.PlayForceFeedback(PlayerFeedbackForce, false, false, n"ShuffleBoard FF");
		}
	}

	UFUNCTION(NetFunction)
	void NetActivatedObstacles(int NetChosenIndex)
	{
		if (ObstaclesChange != nullptr)
			AkComp.HazePostEvent(ObstaclesChange);

		for(auto Obstacle : ObstacleGroups[NetChosenIndex].Obstacles)
			Obstacle.ActivateObstacle();
	}

	UFUNCTION()
	void DeactivateObstacles()
	{
		for(auto Group : ObstacleGroups)
		{
			for(auto Obstacle : Group.Obstacles)
			{
				Obstacle.DeactivateObstacle();
			}
		}
	}
}