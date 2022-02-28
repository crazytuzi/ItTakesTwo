import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.SteeringBehaviors.BoidShapeVisualizer;

class UKeyBirdSpawnerDummyComponent : UActorComponent {}

#if EDITOR

class UKeyBirdSpawnerComponentVisualizer : UBoidObstacleShapeVisualizer
{
    default VisualizedClass = UKeyBirdSpawnerDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UKeyBirdSpawnerDummyComponent Comp = Cast<UKeyBirdSpawnerDummyComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			return;

		AKeyBirdSpawner Spawner = Cast<AKeyBirdSpawner>(Comp.Owner);

		if(Spawner == nullptr)
			return;

		if(Spawner.TargetBoidArea == nullptr)
			return;

		UBoidShapeComponent BoidShape = UBoidShapeComponent::Get(Spawner.TargetBoidArea);

		DrawBoidShape(BoidShape);
    }
}

#endif // EDITOR


event void FOnKeyBirdSpawned(AKeyBird KeyBird);

void ReturnKeyBird(AKeyBird KeyBird)
{
	if(KeyBird == nullptr)
		return;

	AKeyBirdSpawner Spawner = Cast<AKeyBirdSpawner>(KeyBird.Spawner);

	if(Spawner == nullptr)
		return;

	Spawner.ReturnKeyBird(KeyBird);
}

UCLASS(Abstract)
class AKeyBirdSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USkeletalMeshComponent SkeletalMesh;
	default SkeletalMesh.SkeletalMesh = Asset("/Game/Characters/DevilBaby/DevilBaby.DevilBaby");
	default SkeletalMesh.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, NotEditable)
	UKeyBirdSpawnerDummyComponent DummyVisualizer;
	default DummyVisualizer.bIsEditorOnly = true;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(HasControl() && bAutoSpawn)
		{
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(TargetBoidArea == nullptr)
			TargetBoidArea = FindClosestBoidArea(ActorLocation);
	}

	UPROPERTY()
	FOnKeyBirdSpawned OnKeyBirdSpawned;

	// Set spawned actor to this area. If none is selected it will attempt to find one itself.
	UPROPERTY()
	ABoidArea TargetBoidArea;

	UPROPERTY()
	TSubclassOf<AKeyBird> KeyBirdClass;

	UPROPERTY()
	bool bSpawn = true;

	UPROPERTY()
	private bool bAutoSpawn = true;

	// How often we spawn
	UPROPERTY()
	float Interval = 2.0f;

	// Will not be able to spawn more than this. Restricted only by this spawner.
	UPROPERTY()
	int SpawnMax = 10;

	UPROPERTY()
	bool bLimitedSpawn = false;

	UPROPERTY(meta = (EditCondition = "bLimitedSpawn", EditConditionHides))
	int MaxSpawnCount = 10;

	UPROPERTY()
	bool CacheInstances = true;

	int SpawnCountTotal = 0;

	float Elapsed = 0;

	// How many birds are currently spawned
	private int SpawnedCurrent = 0;
	// Network counter for spawning birds.
	private int NetSpawnCount = 0;
	private TArray<AKeyBird> CachedKeyBirds;

	UFUNCTION()
	void SetAutoSpawn(bool bValue)
	{
		if(!HasControl())
			return;

		bAutoSpawn = bValue;
		SetActorTickEnabled(bValue);
	}

	UFUNCTION()
	void SpawnKeyBird()
	{
		if(!bSpawn)
			return;

		if(bLimitedSpawn && SpawnCountTotal >= MaxSpawnCount)
			return;

		if(SpawnedCurrent < SpawnMax)
		{
			SpawnCountTotal++;
			if(CachedKeyBirds.Num() > 0)
			{
				AKeyBird KeyBird = CachedKeyBirds.Last();
				CachedKeyBirds.RemoveAt(CachedKeyBirds.Num() - 1);
				NetSpawnCachedKeyBird(KeyBird);
			}
			else
			{
				NetSpawnKeyBird();
			}
		}
	}

	// Create a new instance of a key bird
	UFUNCTION(NetFunction)
	private void NetSpawnKeyBird()
	{
		AKeyBird KeyBird = Cast<AKeyBird>(SpawnActor(KeyBirdClass, ActorLocation, ActorRotation, bDeferredSpawn = true));
		if(!devEnsure(KeyBird != nullptr))
			return;

		KeyBird.Spawner = this;
		KeyBird.MakeNetworked(this, NetSpawnCount);
		KeyBird.SetControlSide(this);
		KeyBird.SteeringBehavior.BoidArea = TargetBoidArea;
		KeyBird.CombatArea = Cast<AKeyBirdCombatArea>(TargetBoidArea);

		FinishSpawningActor(KeyBird);
		KeyBird.SetKeyBirdEnabled(true);
		SpawnedCurrent++;
		NetSpawnCount++;
	}

	// Re-use a cached instances of a key bird.
	UFUNCTION(NetFunction)
	private void NetSpawnCachedKeyBird(AKeyBird KeyBird)
	{
		SpawnedCurrent++;
		KeyBird.TeleportActor(ActorLocation, ActorRotation);
		KeyBird.ReviveKeyBird();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Elapsed += DeltaTime;

		if(Elapsed > Interval)
		{
			SpawnKeyBird();
			Elapsed = 0;
		}
	}
	
	void ReturnKeyBird(AKeyBird KeyBird)
	{
		if(CachedKeyBirds.Contains(KeyBird))
			return;

		if(KeyBird.Spawner != this)
			return;

		SpawnedCurrent--;

		if(CacheInstances)
			CachedKeyBirds.Add(KeyBird);
		else
			KeyBird.DestroyActor();
	}

}
