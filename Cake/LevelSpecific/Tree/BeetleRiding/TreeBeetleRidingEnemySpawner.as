import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineActor;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingEnemy;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingEnemyManager;
import Peanuts.Triggers.PlayerTrigger;
import Peanuts.Triggers.ActorTrigger;

class UTreeBeetleRidingEnemySpawnerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTreeBeetleRidingEnemySpawnerVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		ATreeBeetleRidingEnemySpawner EnemySpawner = Cast<ATreeBeetleRidingEnemySpawner>(Component.GetOwner());

		FVector LocationOnSpline = EnemySpawner.Spline.GetLocationAtDistanceAlongSpline(EnemySpawner.SpawnDistance, ESplineCoordinateSpace::World);

		DrawDashedLine(EnemySpawner.GetActorLocation(), LocationOnSpline, FLinearColor::Red, 20.f);
		DrawPoint(LocationOnSpline, FLinearColor::Red, 20.f);

		for (auto SpawnData : EnemySpawner.SpawnList)
		{

			FTransform TransformAtDistance = EnemySpawner.Spline.GetTransformAtDistanceAlongSpline(EnemySpawner.SpawnDistance, ESplineCoordinateSpace::World, true);

			float SplineWidth = TransformAtDistance.Scale3D.Y * EnemySpawner.Spline.BaseWidth;
			float Offset = FMath::Clamp(SpawnData.Offset.X, -SplineWidth, SplineWidth);

			FVector SpawnLocation = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * Offset) + (TransformAtDistance.Rotation.UpVector * SpawnData.Offset.Y);
			DrawPoint(SpawnLocation, FLinearColor::Yellow, 40.f);
		}
	}
}

class UTreeBeetleRidingEnemySpawnerVisualizerComponent : UActorComponent
{

}

enum ETreeBeetleRidingEnemyType
{
    LarvaBomberWasp,
    HeavyLarvaBomberWasp,
}

struct FTreeBeetleRidingEnemySpawnerData
{
	UPROPERTY()
	float Delay = 0.f;

	UPROPERTY()
	FVector2D Offset = FVector2D::ZeroVector;

	UPROPERTY()
	ETreeBeetleRidingEnemyType Type = ETreeBeetleRidingEnemyType::LarvaBomberWasp;
}

class ATreeBeetleRidingEnemySpawner : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UTreeBeetleRidingEnemySpawnerVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.SetWorldScale3D(20.f);

	UPROPERTY()
	AConnectedHeightSplineActor ConnectedHeightSplineActor;

	UPROPERTY()
	TSubclassOf<ATreeBeetleRidingEnemy> EnemyClass;

	UPROPERTY()
	APlayerTrigger PlayerTrigger;

	UPROPERTY()
	AActorTrigger ActorTrigger;

	UConnectedHeightSplineComponent Spline;

	ATreeBeetleRidingEnemyManager EnemyManager;

	float SpawnDistance = 0.f;

	float SpawnTimer = 0.f;

	bool bIsActive;

	int SpawnCount = 0;

	UPROPERTY()
	TArray<FTreeBeetleRidingEnemySpawnerData> SpawnList;

	TArray<FTreeBeetleRidingEnemySpawnerData> SavedSpawnList;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (ConnectedHeightSplineActor == nullptr)
			return;

		Spline = ConnectedHeightSplineActor.ConnectedHeightSplineComponent;

		SpawnDistance = Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerTriggered");

		if (ActorTrigger != nullptr)
			ActorTrigger.OnActorEnter.AddUFunction(this, n"OnActorTriggered");

		// Get the EnemyManager
		TArray<AActor> Actors;
		Gameplay::GetAllActorsOfClass(ATreeBeetleRidingEnemyManager::StaticClass(), Actors);
		EnemyManager = Cast<ATreeBeetleRidingEnemyManager>(Actors[0]);

		Spline = ConnectedHeightSplineActor.ConnectedHeightSplineComponent;
		SpawnDistance = Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);

		SavedSpawnList = SpawnList;

	//	StartSpawning();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (!bIsActive)
			return;

		PrintToScreenScaled("SpawnTimer!" + SpawnTimer, 0.f, FLinearColor::Red, 2.f);

		SpawnTimer += DeltaTime;

		if (SpawnList.Num() > 0 && SpawnTimer >= SpawnList[0].Delay)
		{
			NetSpawnEnemy(SpawnList[0]);
			SpawnList.RemoveAt(0);
			SpawnTimer = 0;
		}

		if (!(SpawnList.Num() > 0))
		{
			return; // Prevent respawning
			//SpawnList = SavedSpawnList;
		}
	}

	UFUNCTION()
	void OnPlayerTriggered(AHazePlayerCharacter Player)
	{
		if (bIsActive)
			return;

		StartSpawning();
	}

	UFUNCTION()
	void OnActorTriggered(AHazeActor Actor)
	{
		if (bIsActive)
			return;

		StartSpawning();
	}	

	UFUNCTION()
	void StartSpawning()
	{
		PrintScaled("StartSpawning!", 1.f, FLinearColor::Red, 2.f);
		bIsActive = true;
	}

	UFUNCTION(NetFunction)
	void NetSpawnEnemy(FTreeBeetleRidingEnemySpawnerData EnemyData)
	{	
	//	ATreeBeetleRidingEnemy Enemy = EnemyManager.GetEnemy();

		ATreeBeetleRidingEnemy Enemy = Cast<ATreeBeetleRidingEnemy>(SpawnActor(EnemyClass, bDeferredSpawn = true, Level = this.Level));
		
		UTreeBeetleRidingComponent BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Game::GetMay());
	
		Enemy.Speed = -3000.f;
		Enemy.TargetBeetle = BeetleRidingComponent.Beetle;
		Enemy.SplineFollowerComponent.SplineActor = ConnectedHeightSplineActor;
		Enemy.SplineFollowerComponent.Spline = Spline;
		Enemy.Distance = SpawnDistance;
		Enemy.Offset = EnemyData.Offset.X;
		Enemy.HeightOffset = EnemyData.Offset.Y;

		Enemy.MakeNetworked(this, SpawnCount);

		SpawnCount++;

		FinishSpawningActor(Enemy);

//		PrintScaled("Spawn!", 1.f, FLinearColor::Red, 2.f);
	}	
}