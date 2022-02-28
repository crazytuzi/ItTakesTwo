import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboySettings;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

enum EHazeboyPickupType
{
	Health,
	Haste,
	SuperCharge,
	MAX
}

class AHazeboyPickup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;
	default MeshRoot.RelativeLocation = FVector(0.f, 0.f, 200.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USphereComponent PickupSphere;
	default PickupSphere.SphereRadius = 100.f;

	UPROPERTY(EditDefaultsOnly, Category = "Pickup")
	EHazeboyPickupType Type;

	FTransform MeshOrigin;
	AHazeboyPickupSpawner Spawner;

	bool bIsEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshOrigin = MeshRoot.RelativeTransform;
		HazeboyRegisterResetCallback(this, n"ResetPickup");
	}

	void TriggerPickup()
	{
		if (!bIsEnabled)
			return;

		if (Spawner != nullptr)
			Spawner.StartSpawningNewPickup();

		DisableActor(this);
		bIsEnabled = false;
	}

	UFUNCTION()
	void ResetPickup()
	{
		if (!bIsEnabled)
			EnableActor(this);

		bIsEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FTransform BounceTransform;
		BounceTransform.Location = FVector::UpVector * FMath::Sin(Time::GameTimeSeconds * 2.1f) * 40.f;
		BounceTransform.Rotation = FQuat(FVector::UpVector, Time::GameTimeSeconds * 1.2f);

		MeshRoot.RelativeTransform = MeshOrigin * BounceTransform;
	}
}

class AHazeboyPickupSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditDefaultsOnly, Category="Pickups")
	TArray<TSubclassOf<AHazeboyPickup>> PickupTypes;
	float SpawnTimer = 0.f;

	AHazeboyPickup CurrentPickup;
	int SpawnIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartSpawningNewPickup();
		HazeboyRegisterResetCallback(this, n"StartSpawningNewPickup");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentPickup == nullptr)
		{
			SpawnTimer -= DeltaTime;
			if (SpawnTimer < 0.f && HasControl())
			{
				int PickupIndex = FMath::RandRange(0, PickupTypes.Num() - 1);
				NetSpawnPickup(PickupIndex);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSpawnPickup(int PickupIndex)
	{
		if (CurrentPickup != nullptr)
			CurrentPickup.DestroyActor();

		SpawnIndex++;

		CurrentPickup = Cast<AHazeboyPickup>(SpawnActor(PickupTypes[PickupIndex], ActorLocation, ActorRotation));
		CurrentPickup.MakeNetworked(this, SpawnIndex);
		CurrentPickup.Spawner = this;
	}

	UFUNCTION()
	void StartSpawningNewPickup()
	{
		if (CurrentPickup != nullptr)
			CurrentPickup.DestroyActor();
		CurrentPickup = nullptr;

		SpawnTimer = Hazeboy::PickupSpawnTime;
	}
}