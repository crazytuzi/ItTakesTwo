import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingSpline;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingTarget;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingAxeManager;

enum EAxeMovingTargetStage
{
	TutorialStart,
	BottomLanes,
	UpperAndBottomLanes,
	AllLanes,
};

enum EAxeThrowingSplineType
{
	None,
	Front,
	BackLower,
	BackUpper,
	Left,
	Right,
}

struct FAxeMovingTargetLanes
{
	UPROPERTY()
	TMap<EAxeThrowingSplineType, AAxeThrowingSpline> TypeToLane;
}

struct FAxeMovingTargetStage
{
	UPROPERTY()
	TArray<EAxeThrowingSplineType> ActiveLanes;

	UPROPERTY()
	float Duration = 0.f;
}

event void FTargetHitScore(AHazePlayerCharacter Player, float Score, FVector HitLocation, bool bIsDoublePoints);
// event void FAddTargetToPlayerComp(AAxeThrowingTarget Target, int Index);
// event void FRemoveTargetToPlayerComp(AAxeThrowingTarget Target, int Index);
event void FSpeedUpActivated();

class AAxeThrowingTargetManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent ForwardArrow;

	UPROPERTY(Category = "AxeThrowing")
	TPerPlayer<FAxeMovingTargetLanes> PlayerLanes;

	UPROPERTY(Category = "AxeThrowing")
	TArray<AActor> TutorialSpawnPointsMay;

	UPROPERTY(Category = "AxeThrowing")
	TArray<AActor> TutorialSpawnPointsCody;

	UPROPERTY(Category = "AxeThrowing")
	TArray<FAxeMovingTargetStage> Stages;

	UPROPERTY(Category = "AxeThrowing")
	float SpeedUpTime = 50.f;

	TArray<AAxeThrowingTarget> AxeTargetsArray;

	FTargetHitScore OnTargetHitScore;

	FSpeedUpActivated OnSpeedUpActivated;

	bool bCanSpawn;

	//*** TARGET SPEED ***//
	const float FastSpeedMultiplier = 1.4f;

	//*** SPECIAL TARGETS ***//
	TPerPlayer<int> SpecialCounter;
	const int SpecialInterval = 8;
	const float SpecialSpeedMultiplier = 1.3f;

	int StageIndex = 0;
	float StageTimer = 0.f;
	float TotalTime = 0.f;

	int NumTutorialTargets = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(AxeTargetsArray);

		auto Players = Game::Players;
		for(int i=0; i<AxeTargetsArray.Num(); ++i)
		{
			auto Target = AxeTargetsArray[i];

			// Divvy up the targets for each player
			Target.PlayerOwner = Players[i % 2];
			Target.OnScoreHitEvent.AddUFunction(this, n"OnTargetHit");
			Target.WorldForward = ForwardArrow.ForwardVector;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bCanSpawn)
			return;

		if (HasControl())
		{
			UpdateTargetSpawning(DeltaTime);
			UpdateStages(DeltaTime);
		}
	}

	UFUNCTION()
	void UpdateTargetSpawning(float DeltaTime)
	{
		FAxeMovingTargetStage Stage = Stages[StageIndex];

		// Go through each _lane type_ for _each stage_ for _each player_
		for(auto Player : Game::Players)
		{
			for(auto LaneType : Stage.ActiveLanes)
			{	
				// Translate lane type into lane...
				AAxeThrowingSpline Lane;
				PlayerLanes[Player].TypeToLane.Find(LaneType, Lane);

				if (!devEnsure(Lane != nullptr, "Lane " + LaneType + " for player " + Player + " was nullptr. Was the manager set up properly? :hmm:"))
					continue;

				// For back-and-forth lanes, we only allwo one target at a time
				if (Lane.bBackAndForth && Lane.CurrentTargetCount > 0)
					continue;

				Lane.SpawnTimer += DeltaTime;

				if (Lane.SpawnTimer >= Lane.DelayDuration)
				{
					// Time to spawn, oh boy!

					// Every Nth spawn, its _special_
					EPointWorth Worth = EPointWorth::Normal;

					SpecialCounter[Player]++;

					if (SpecialCounter[Player] >= SpecialInterval)
					{
						SpecialCounter[Player] = 0;
						Worth = EPointWorth::Special;
					}

					FindAndActivateTargetOnLane(Player, Lane, Worth);
					Lane.SpawnTimer = 0.f;
				}
			}
		}
	}

	void UpdateStages(float DeltaTime)
	{
		if (StageIndex < Stages.Num() - 1)
		{
			StageTimer += DeltaTime;

			if (StageTimer >= Stages[StageIndex].Duration)
				NetSetStage(StageIndex + 1);
		}

		// Speed all targets up after a certain time :)
		if (TotalTime < SpeedUpTime)
		{
			TotalTime += DeltaTime;

			if (TotalTime >= SpeedUpTime)
			{
				NetSetSpeedUp();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetSpeedUp()
	{
		// Uh oh! This came in after we stopped (remote side)
		if (!bCanSpawn)
			return;

		OnSpeedUpActivated.Broadcast();

		for(auto Target : AxeTargetsArray)
			Target.bIsSpeedUp = true;
	}

	UFUNCTION(NetFunction)
	void NetSetStage(int NewStageIndex)
	{
		StageIndex = NewStageIndex;
		StageTimer = 0.f;
	}

	UFUNCTION()
	void BeginSpawn()
	{
		bCanSpawn = true;
		StageIndex = 0;
		StageTimer = 0.f;
		NumTutorialTargets = 0;
		TotalTime = 0.f;

		// Activate all the tutorial targets!
		if (HasControl())
		{
			for (AActor SpawnPoint : TutorialSpawnPointsMay)
			{
				FindAndActivateTargetOnComponent(Game::May, SpawnPoint.RootComponent);
			}

			for (AActor SpawnPoint : TutorialSpawnPointsCody)
			{
				FindAndActivateTargetOnComponent(Game::Cody, SpawnPoint.RootComponent);
			}		
		}
	}

	UFUNCTION()
	void TargetsEndGame()
	{
		bCanSpawn = false;

		for (AAxeThrowingTarget Target : AxeTargetsArray)
		{
			if (Target.bIsActive)
			{
				if (Target.bIsTutorial)
					Target.TutorialGameEnded();
				else
					Target.TargetEndGame();
			}

			Target.bIsSpeedUp = false;
		}
	}

	UFUNCTION()
	void OnTargetHit(AAxeThrowingTarget Target, float ScoreToAdd, bool bIsDoublePoints)
	{
		OnTargetHitScore.Broadcast(Target.PlayerOwner, ScoreToAdd, Target.ActorLocation, bIsDoublePoints);

		// If all tutorials gets hit, advance to the next phase early
		// For both players right now...
		if (Target.bIsTutorial)
		{
			NumTutorialTargets--;

			if (HasControl() && NumTutorialTargets == 0 && StageIndex == 0)
			{
				NetSetStage(1);
			}
		}
	}

	void FindAndActivateTargetOnLane(AHazePlayerCharacter Player, AAxeThrowingSpline Lane, EPointWorth PointWorth)
	{
		ensure(HasControl());
		for (AAxeThrowingTarget Target : AxeTargetsArray)
		{
			if (Target.PlayerOwner != Player)
				continue;

			if (!Target.bIsActive)
			{
				NetActivateTargetOnLane(Target, Lane, PointWorth);
				break;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetActivateTargetOnLane(AAxeThrowingTarget Target, AAxeThrowingSpline Lane, EPointWorth PointWorth)
	{
		// Might still be active on remote side, so make sure we deactivate
		if (Target.bIsActive)
			Target.DeactivateTarget();

		// Hard-coded tutorial, should be fine?
		Target.ActivateTarget(Lane, PointWorth, false);
	}

	void FindAndActivateTargetOnComponent(AHazePlayerCharacter Player, USceneComponent Comp)
	{
		ensure(HasControl());
		for (AAxeThrowingTarget Target : AxeTargetsArray)
		{
			if (Target.PlayerOwner != Player)
				continue;

			if (!Target.bIsActive)
			{
				NetActivateTargetOnComponent(Target, Comp);
				NumTutorialTargets++;
				break;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetActivateTargetOnComponent(AAxeThrowingTarget Target, USceneComponent Comp)
	{
		// Might still be active on remote side, so make sure we deactivate
		if (Target.bIsActive)
			Target.DeactivateTarget();

		// Hard-coded worths and tutorial, should be fine?
		Target.ActivateTarget(Comp, EPointWorth::Normal, true);
	}
}