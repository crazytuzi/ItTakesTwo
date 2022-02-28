import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyObstacleActor;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;

event void FOnHorseDerbyCloseObstacleDoors();

struct FHorseDerbyObstacleStruct
{
	UPROPERTY()
	TArray<AHorseDerbyObstacleActor> JumpObstacles;
	
	UPROPERTY()
	TArray<AHorseDerbyObstacleActor> CrouchObstacles;

	int PoolSize = 20;

	int NetworkIDOffset;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHazeActor> JumpObstacle;
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHazeActor> CrouchObstacle;

	bool ResetInProgress = false;

	void InitializeObstacles(int IndexOffset, UHorseDerbyObstacleManagerComponent Instigator, AHazePlayerCharacter Player)
	{
		int NetIndex = 1;
		
		for(AHorseDerbyObstacleActor Obstacle : JumpObstacles)
		{
			Obstacle.MakeNetworked(NetIndex + 3300 + IndexOffset);

			Obstacle.SetControlSide(Player);
			Obstacle.SetCapabilityAttributeObject(n"ObstacleManager", Instigator);

			Obstacle.InitializeObstacle();
			Obstacle.DisableEvent.AddUFunction(Instigator, n"DeactivateObstacle");
			Obstacle.DisableActor(Instigator);

			if(!Obstacle.IsActorDisabled())
				Obstacle.DisableActor(Instigator);
			
			NetIndex++;
		}

		for(AHorseDerbyObstacleActor Obstacle : CrouchObstacles)
		{
			Obstacle.MakeNetworked(NetIndex + 3400 + IndexOffset);

			Obstacle.SetControlSide(Player);
			Obstacle.SetCapabilityAttributeObject(n"ObstacleManager", Instigator);

			Obstacle.InitializeObstacle();
			Obstacle.DisableEvent.AddUFunction(Instigator, n"DeactivateObstacle");
			Obstacle.DisableActor(Instigator);

			if(!Obstacle.IsActorDisabled())
				Obstacle.DisableActor(Instigator);
			
			NetIndex++;
		}
	}

	void ActivateJumpObstacles(UHorseDerbyObstacleManagerComponent Instigator, ADerbyHorseSplineTrack Track, ADerbyHorseActor TargetHorse, AHazePlayerCharacter Player)
	{
		for(AHorseDerbyObstacleActor CurrentObstacle : JumpObstacles)
		{
			if(CurrentObstacle.IsActorDisabled(Instigator) /* && !CurrentObstacle.IsAnyCapabilityActive(CapabilityTags::Movement)*/)
			{
				// if (Game::May.HasControl())
				// 	Print("___M JumpObstacles");
				
				CurrentObstacle.SetActorLocation(Track.GetWorldLocationAtObstacleSpawn());
				CurrentObstacle.SplineTrack = Track;
				CurrentObstacle.EnableActor(Instigator);
				CurrentObstacle.ActiveObstacle = true;
				CurrentObstacle.bReverseResetDirection = false;
				CurrentObstacle.SetTargetPlayer(TargetHorse);
				return;
			}
		}
	}

	void ActivateCrouchObstacles(UHorseDerbyObstacleManagerComponent Instigator, ADerbyHorseSplineTrack Track, ADerbyHorseActor TargetHorse, AHazePlayerCharacter Player)
	{
		for(AHorseDerbyObstacleActor CurrentObstacle : CrouchObstacles)
		{
			if(CurrentObstacle.IsActorDisabled(Instigator) /* && !CurrentObstacle.IsAnyCapabilityActive(CapabilityTags::Movement)*/)
			{
				// if (Game::May.HasControl())
				// 	Print("---L CrouchObstacles");
				
				CurrentObstacle.SetActorLocation(Track.GetWorldLocationAtObstacleSpawn());
				CurrentObstacle.SplineTrack = Track;
				CurrentObstacle.EnableActor(Instigator);
				CurrentObstacle.ActiveObstacle = true;
				CurrentObstacle.bReverseResetDirection = false;
				CurrentObstacle.SetTargetPlayer(TargetHorse);
				return;
			}
		}
	}

	void BeginResetOfActiveObstacles(ADerbyHorseActor HorseActor)
	{
		float HorseDistanceAlongSpline = HorseActor.SplineTrack.SplineComp.GetDistanceAlongSplineAtWorldLocation(HorseActor.ActorLocation);
		float ObstacleDistanceAlongSpline;

		for (int i = 0; i < CrouchObstacles.Num(); i++)
		{
			if(CrouchObstacles[i].ActiveObstacle && CrouchObstacles[i].SplineTrack == HorseActor.SplineTrack)
			{
				ObstacleDistanceAlongSpline = CrouchObstacles[i].SplineTrack.SplineComp.GetDistanceAlongSplineAtWorldLocation(CrouchObstacles[i].ActorLocation);

				if(ObstacleDistanceAlongSpline < HorseDistanceAlongSpline)
				{
					//Obstacle is behind player and should keep moving in towards start of spline

				}
				else if(ObstacleDistanceAlongSpline >= HorseDistanceAlongSpline)
				{
					//Obstacle is infront of player and should reverse back unto spawn location.
					CrouchObstacles[i].bReverseResetDirection = true;
				}
			}
		}

		for (int i = 0; i < JumpObstacles.Num(); i++)
		{
			if(JumpObstacles[i].ActiveObstacle && JumpObstacles[i].SplineTrack == HorseActor.SplineTrack)
			{
				ObstacleDistanceAlongSpline = JumpObstacles[i].SplineTrack.SplineComp.GetDistanceAlongSplineAtWorldLocation(JumpObstacles[i].ActorLocation);

				if(ObstacleDistanceAlongSpline < HorseDistanceAlongSpline)
				{
					//Obstacle is behind player and should keep moving in towards start of spline

				}
				else if(ObstacleDistanceAlongSpline >= HorseDistanceAlongSpline)
				{
					//Obstacle is infront of player and should reverse back unto spawn location.
					JumpObstacles[i].bReverseResetDirection = true;
				}
			}
		}
	}
}

class UHorseDerbyObstacleManagerComponent : UActorComponent
{
	//This component manages spawning / Storing / handling UBeetleDestroyObstaclesCapability

	//Have timer running and modify DeltaTime being added (Add/Multiyply delta time being added to timer ticking)
	//Timer runs in main manager, calls functions on this comp to perform obstacle related actions.

	UPROPERTY(Category = "Settings")
	float ObstacleSpeed = 250;

	UPROPERTY()
	TPerPlayer<FHorseDerbyObstacleStruct> ObstacleData;
	default ObstacleData[1].NetworkIDOffset = 20;

	int PoolSize = 20;

	UPROPERTY(Category = "Debug")
	bool Debug = false;

	UPROPERTY()
	FOnHorseDerbyCloseObstacleDoors CloseDoorsEvent;

	bool ResetInProgress = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Debug)
		{
			int C = 0;
			int J = 0;

			for (FHorseDerbyObstacleStruct Struct : ObstacleData)
			{
				for(int i = 0; i < PoolSize; i++)
				{
					if(!Struct.JumpObstacles[i].IsActorDisabled() && Struct.JumpObstacles[i] != nullptr)
						J++;
					if(!Struct.CrouchObstacles[i].IsActorDisabled() && Struct.CrouchObstacles[i] != nullptr)
						C++;
				}
			}
		}
	}

	void Initialize()
	{
		ObstacleData[0].InitializeObstacles(0 ,this, Game::May);
		ObstacleData[1].InitializeObstacles(25 ,this, Game::Cody);
	}

	void ActivateJumpObstacle(ADerbyHorseSplineTrack Track, ADerbyHorseActor TargetHorse, AHazePlayerCharacter Player)
	{
		ObstacleData[Player].ActivateJumpObstacles(this, Track, TargetHorse, Player);
	}

	void ActivateCrouchObstacle(ADerbyHorseSplineTrack Track, ADerbyHorseActor TargetHorse, AHazePlayerCharacter Player)
	{
		ObstacleData[Player].ActivateCrouchObstacles(this, Track, TargetHorse, Player);
	}

	UFUNCTION()
	void DeactivateObstacle(AHorseDerbyObstacleActor Obstacle)
	{
		if (!Obstacle.IsActorDisabled())
			Obstacle.DisableActor(this);
		
		Obstacle.ActiveObstacle = false;

		if(ResetInProgress)
		{
			if(VerifyAllObstaclesInactive())
				CloseDoorsEvent.Broadcast();
		}
	}

	//Verify active obstacles and direction based on player position.
	void BeginResetOfActiveObstacles(ADerbyHorseActor HorseActor, AHazePlayerCharacter Player)
	{
		ResetInProgress = true;

		ObstacleData[Player].BeginResetOfActiveObstacles(HorseActor);
	}

	bool VerifyAllObstaclesInactive()
	{
		for (FHorseDerbyObstacleStruct Struct : ObstacleData)
		{
			for(AHorseDerbyObstacleActor Obstacle : Struct.CrouchObstacles)
			{
				if (Obstacle != nullptr)
					if(Obstacle.ActiveObstacle)
						return false;
			}

			for (AHorseDerbyObstacleActor Obstacle : Struct.JumpObstacles)
			{
				if (Obstacle != nullptr)
					if(Obstacle.ActiveObstacle)
						return false;
			}	
		}

		return true;
	}
}