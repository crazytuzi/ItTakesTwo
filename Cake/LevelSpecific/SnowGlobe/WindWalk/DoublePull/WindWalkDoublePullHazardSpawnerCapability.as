import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;
import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullHazardMovementCapability;

struct FRandomFloatInRange
{
	UPROPERTY()
	float Min = 0.f;

	UPROPERTY()
	float Max = 0.f;

	float GetRandom()
	{
		return FMath::RandRange(Min, Max);
	}
}

class UWindWalkDoublePullHazardSpawnerCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::HazardSpawner);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	UPROPERTY()
	FRandomFloatInRange SpawnPeriod;
	default SpawnPeriod.Min = 3.f;
	default SpawnPeriod.Max = 9.f;

	UPROPERTY()
	const int MaxSimultaneousHazards = 5.f;

	AWindWalkDoublePullActor DoublePullActor;
	UDoublePullComponent DoublePullComponent;

	const int InitialPoolSize = 5;

	TArray<AWindWalkDoublePullHazard> HazardPool;

	FVector CenterSpawnPoint;
	FVector SplineUp;

	float OffsetNoise;

	float SpawnTimer;
	float ElapsedTime;

	bool bDeliberateHazardMiss;
	bool bShouldSpawnHazard;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DoublePullActor = Cast<AWindWalkDoublePullActor>(Owner);
		DoublePullComponent = UDoublePullComponent::Get(Owner);

		float SplineEnd = DoublePullComponent.Spline.GetSplineLength();
		FVector SplineVector = DoublePullComponent.Spline.GetDirectionAtSplinePoint(2, ESplineCoordinateSpace::World);

		CenterSpawnPoint = DoublePullComponent.Spline.GetLocationAtDistanceAlongSpline(SplineEnd, ESplineCoordinateSpace::World) + Owner.MovementWorldUp * 400.f + SplineVector * 1400.f;
		SplineUp = DoublePullComponent.Spline.GetUpVectorAtSplinePoint(0, ESplineCoordinateSpace::World);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!DoublePullComponent.AreBothPlayersInteracting())
			return EHazeNetworkActivation::DontActivate;

		if(!DoublePullActor.bCanSpawnHazards)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.AddValue(n"SpawnTimer", SpawnPeriod.GetRandom());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(bDeliberateHazardMiss = ActivationParams.GetActionState(n"bDeliberateHazardMiss"))
			SpawnTimer = 0.f;
		else
			SpawnTimer = ActivationParams.GetValue(n"SpawnTimer");

		DoublePullActor.bDeliberateHazardMiss = false;

		// Initialize pool
		for(int i = 0; i < InitialPoolSize; i++)
			HazardPool.Add(CreateHazard());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			ElapsedTime += DeltaTime;
			if(CanControlSpawnHazard())
			{
				ElapsedTime = 0.f;
				SpawnTimer = FMath::Max(Network::PingRoundtripSeconds * 2, SpawnPeriod.GetRandom());
				NetSetShouldSpawnHazard(FMath::RandRange(-1000.f, 1000.f));
			}
		}

		if(bShouldSpawnHazard)
		{
			bShouldSpawnHazard = false;
			SpawnAndLaunchHazard();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!DoublePullComponent.AreBothPlayersInteracting())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SpawnTimer = 0.f;
		ElapsedTime = 0.f;
		bDeliberateHazardMiss = false;
	}

	AWindWalkDoublePullHazard CreateHazard()
	{
		int Id = DoublePullActor.SpawnedHazards.Num() + HazardPool.Num() + 1;

		FName HazardName = FName("DoublePullHazard_" + String::Conv_IntToString(Id));
		AWindWalkDoublePullHazard Hazard = Cast<AWindWalkDoublePullHazard>(SpawnActor(DoublePullActor.HazardClass, CenterSpawnPoint, Name = HazardName, bDeferredSpawn = true));

		Hazard.MakeNetworked(Owner, FNetworkIdentifierPart(Id));
		Hazard.SetControlSide(Owner);
		FinishSpawningActor(Hazard);

		Hazard.OnReadyForRespawnEvent.AddUFunction(this, n"OnHazardReadyForRespawn");

		return Hazard;
	}

	void SpawnAndLaunchHazard()
	{
		// Get params
		FVector SpawnLocation, SpawnDirection;
		GetSpawnParams(SpawnLocation, SpawnDirection);

		FRotator SpawnRotation = FRotator(FMath::RandRange(0.f, 360.f), FMath::RandRange(0.f, 360.f), FMath::RandRange(0.f, 360.f));

		// Position at spawning point
		AWindWalkDoublePullHazard Hazard = GetPooledHazard();
		Hazard.Initialize(SpawnLocation, SpawnRotation, bDeliberateHazardMiss);

		// Start moving
		FVector AutoBreakPoint = DoublePullComponent.Spline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World) + SpawnDirection * 500.f;
		Hazard.StartMoving(SpawnDirection, AutoBreakPoint);

		// Add hazard to spawned list in wind walk double pull actor
		DoublePullActor.SpawnedHazards.Add(Hazard);
	}

	void GetSpawnParams(FVector& SpawnLocation, FVector& SpawnDirection)
	{
		FVector SpawnOffset;
		if(bDeliberateHazardMiss)
		{
			const float DistanceFromSpline = 1200.f;
			SpawnOffset = DoublePullComponent.Spline.GetLocationAtSplinePoint(2, ESplineCoordinateSpace::World) - DoublePullComponent.Spline.GetLocationAtSplinePoint(2, ESplineCoordinateSpace::World) + DoublePullComponent.Spline.GetRightVectorAtSplinePoint(2, ESplineCoordinateSpace::World) * (FMath::RandBool() ? DistanceFromSpline : -DistanceFromSpline);
			SpawnOffset = SpawnOffset.ConstrainToPlane(SplineUp);
			SpawnLocation = CenterSpawnPoint + SpawnOffset;

			SpawnDirection = -DoublePullComponent.Spline.GetDirectionAtSplinePoint(2.f, ESplineCoordinateSpace::World);
		}
		else
		{
			SpawnOffset = DoublePullActor.ActorLocation - DoublePullComponent.Spline.FindLocationClosestToWorldLocation(DoublePullActor.ActorLocation, ESplineCoordinateSpace::World);
			SpawnOffset = SpawnOffset.ConstrainToPlane(SplineUp);

			// Add a little offset to the offset
			SpawnLocation = CenterSpawnPoint + SpawnOffset + SpawnOffset.GetSafeNormal() * OffsetNoise;
			SpawnDirection = (DoublePullActor.ActorCenterLocation - CenterSpawnPoint).GetSafeNormal();
		}

		SpawnDirection = SpawnDirection.ConstrainToPlane(SplineUp);
	}

	AWindWalkDoublePullHazard GetPooledHazard()
	{
		AWindWalkDoublePullHazard Hazard;
		if(HazardPool.Num() == 0)
			HazardPool.Add(CreateHazard());

		Hazard = HazardPool.Last();
		HazardPool.RemoveAt(HazardPool.Num() - 1);

		return Hazard;
	}

	bool CanControlSpawnHazard()
	{
		if(ElapsedTime < SpawnTimer) 
			return false;
		
		if(DoublePullActor.SpawnedHazards.Num() >= MaxSimultaneousHazards)
			return false;

		if(DoublePullActor.bIsInStartZone)
			return false;

		if(DoublePullActor.bIsTumbling)
			return false;

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnHazardReadyForRespawn(AWindWalkDoublePullHazard Hazard)
	{
		DoublePullActor.SpawnedHazards.Remove(Hazard);
		HazardPool.Add(Hazard);
	}

	UFUNCTION(NetFunction)
	void NetSetShouldSpawnHazard(float NetOffsetNoise)
	{
		OffsetNoise = NetOffsetNoise;
		bShouldSpawnHazard = true;
	}
}