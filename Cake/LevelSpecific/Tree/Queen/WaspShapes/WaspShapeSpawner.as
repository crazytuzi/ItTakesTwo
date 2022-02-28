import Peanuts.Spline.SplineComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class UWaspShapeSpawner : USceneComponent
{
	UHazeSplineComponent Spline;
	TArray<UStaticMeshComponent> SpawnedWasps;
	TArray<float> WaspProgress;
	
	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY()
	int TotalWaspsToSpawn = 20;

	UPROPERTY()
	float Damage = 0.5;

	UPROPERTY()
	UStaticMesh MeshToSpawn;

	FVector StartLocation;
	FVector SplineDirection;
	float Distance;

	UPROPERTY()
	float WaspSpeed = 100;

	bool bShouldIterate;

	float GapBetweenWasps = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Setup();
	}

	void StartSpawning()
	{
		for(float i : WaspProgress)
		{
			i = 0;
		}
		for (UStaticMeshComponent i : SpawnedWasps)
		{
			i.SetVisibility(true);
		}

		bShouldIterate = true;
	}

	UFUNCTION()
	void Setup()
	{
		Spline = UHazeSplineComponent::Get(Owner);
		StartLocation = Spline.GetLocationAtDistanceAlongSpline(0, ESplineCoordinateSpace::World);
		SplineDirection = Spline.GetDirectionAtDistanceAlongSpline(0, ESplineCoordinateSpace::World);
		Distance = Spline.GetSplineLength();

		for (int i = 0; i < TotalWaspsToSpawn ; i++)
		{
			UStaticMeshComponent Mesh = UStaticMeshComponent::Create(Owner);
			SpawnedWasps.Add(Mesh);
			Mesh.SetStaticMesh(MeshToSpawn);
			Mesh.AttachTo(this, AttachType = EAttachLocation::SnapToTarget);
			Mesh.SetCastShadow(false);
			WaspProgress.Add(0);
			Mesh.SetVisibility(false);
		}

		GapBetweenWasps = Spline.GetSplineLength() / TotalWaspsToSpawn;
		bShouldIterate = true;
	}

	void StopSpawning()
	{
		bShouldIterate = false;
		for (UStaticMeshComponent i : SpawnedWasps)
		{
			i.SetVisibility(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldIterate)
		{
			MoveWaspsAlongSpline(DeltaTime);
		}
	}

	void MoveWaspsAlongSpline(float Deltatime)
	{
		for (int i = 0; i < TotalWaspsToSpawn; i++)
		{
			if (i < TotalWaspsToSpawn -1)
			{
				if (FMath::Abs(WaspProgress[i+1] - WaspProgress[i]) < GapBetweenWasps)
				{
					continue;
				}
			}

			WaspProgress[i] += WaspSpeed * Deltatime;

			if (WaspProgress[i] > Distance)
			{
				WaspProgress[i] = 0;
			}


			//FVector ActorLocation = StartLocation + SplineDirection.GetSafeNormal() * WaspProgress[i];
			FVector ActorLocation = Spline.GetLocationAtDistanceAlongSpline(WaspProgress[i], ESplineCoordinateSpace::World);
			SpawnedWasps[i].SetWorldLocation(ActorLocation);
			CalcDamage(ActorLocation);
		}
	}

	void CalcDamage(FVector WorldPos)
	{
		for (AHazePlayerCharacter i : Game::Players)
		{
			if (i.ActorLocation.Distance(WorldPos) < 100)
			{
				i.DamagePlayerHealth(Damage, DamageEffect);
			}
		}
	}
}