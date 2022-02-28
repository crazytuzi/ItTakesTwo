
// Will be added on the actor which will be deployed by deployer.

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class USwarmDeployedBombComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	FVector ConstantGravity = FVector(0.f, 0.f, -3000.f);

	UPROPERTY()
	float Stiffness = 20.f;

	UPROPERTY()
	float Damping = 0.7f;

	UPROPERTY()
 	UNiagaraSystem SplashEffect = Asset("/Game/Effects/Gameplay/WaspSwarm/Wasp_Water_Splash3X.Wasp_Water_Splash3X");

	bool bSplashesSpawned = false;

	bool bSleeping = true;

	FHazeAcceleratedVector Scale;
	FHazeAcceleratedVector LinearMovement;
	FHazeAcceleratedRotator AngularMovement;
	TArray<AActor> IgnoreActors;

	float SwitchToBuoyancy_DistanceThreshold = 100.f;
	
	// we'll disable the updater for this bomb once 
	// the velocity comes to rest with this velocity.
	float SleepThreshold = 0.1f;

	// We don't use "targetLocation" because we want the bomb 
	// to inherit the swarms velocity when dropped. 
	// but we want it to the hit the water surface though!
	float TargetZ = 0.f;

	FVector TargetScale = FVector::OneVector;

	// Might be replaced with Impact Normal later.
	FRotator TargetRotation = FRotator::ZeroRotator;

	void UpdateTargetZ() 
	{
		TargetZ = FindGroundZ();
	}

	void Sleep(bool bSleep)
	{
		SetComponentTickEnabled(!bSleep);
		bSleeping = bSleep;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bSleeping)
			return;

		if (ShouldSleep())
		{
			bSleeping = true;
			SetComponentTickEnabled(false);
			return;
		}

		//@TODO: use buoyancy instead of spring later. 
		if (ShouldSwitchToBuoyancy())
		{
			ApplySpringMovement(DeltaTime);
			SpawnSplashes();
		}
		else
		{
			ApplyGravityMovement(DeltaTime);
		}

		ApplySpringAngularMovement(DeltaTime);
		ExpandToOriginalScale(DeltaTime);
	}

	void SpawnSplashes() 
	{
		if (bSplashesSpawned)
			return;

		for (int i = 0; i < 30; i++)
		{
			FVector SpawnLocation = LinearMovement.Value;
			SpawnLocation.Z = TargetZ + FMath::RandRange(0.f, 50.f);
			SpawnLocation += RandomPointWithinCircle(1000.f);

			Niagara::SpawnSystemAtLocation(
				SplashEffect,
				SpawnLocation,
				TargetRotation
			);

// 			Niagara::SpawnSystemAttached(
// 				SplashEffect,
// 				GetOwner().GetRootComponent(),
// 				NAME_None,
// 				LinearMovement.Value,
// 				TargetRotation,
// 				EAttachLocation::KeepWorldPosition,
// 				true
// 			);

		}

		bSplashesSpawned = true;
	}

	void ApplyNoise(const float DeltaTime) 
	{
		const FVector Loc = LinearMovement.Value;
		const FVector Noise = Noise::GetCurlNoise(Loc, 50.f, 2000.f) * DeltaTime;
//  		LinearMovement.Velocity += Noise;
		AngularMovement.Velocity += FRotator::MakeFromEuler(Noise);
	}

	FVector RandomPointWithinCircle(float CircleRadius) const
	{
		FVector Point = FVector::ZeroVector;
		float L;
		do
		{
			// Check random vectors in the unit circle so result is statistically uniform.
			Point.X = FMath::FRand() * 2.f - 1.f;
			Point.Y = FMath::FRand() * 2.f - 1.f;
			L = Point.SizeSquared();
		}
		while (L > 1.0f);
		return Point * CircleRadius;
	}

	FVector RandomPointOnCircle(float CircleRadius) const 
	{
		FVector Point = FVector::ZeroVector;
		const float RandomAngle = FMath::FRand() * PI * 2.f;
		Point.X = FMath::Cos(RandomAngle) * CircleRadius;
		Point.Y = FMath::Sin(RandomAngle) * CircleRadius;
		return Point;
	}

	bool ShouldSwitchToBuoyancy() const
	{
		const float DistToTargetZ = LinearMovement.Value.Z - TargetZ;
		return DistToTargetZ < SwitchToBuoyancy_DistanceThreshold;
	}

	bool ShouldSleep() const 
	{
		return (LinearMovement.Velocity.SizeSquared() < SleepThreshold)
			&& (AngularMovement.Velocity.Euler().SizeSquared() < SleepThreshold)
			&& (FMath::IsNearlyEqual(LinearMovement.Value.Z, TargetZ, SleepThreshold))
			&& (AngularMovement.Value.Equals(TargetRotation, SleepThreshold))
			&& (Scale.Value.Equals(TargetScale, SleepThreshold));
	}

	void ApplyGravityMovement(float DeltaTime)
	{
		// calc delta movement
		FVector DeltaMove = LinearMovement.Velocity * DeltaTime;
		DeltaMove += ConstantGravity * 0.5f * DeltaTime * DeltaTime;

		// apply delta movement
		GetOwner().AddActorWorldOffset(DeltaMove);

		// update velocity 
		LinearMovement.Velocity += ConstantGravity * DeltaTime;
		LinearMovement.Value = GetOwner().GetActorLocation();
	}

	void ApplySpringAngularMovement(float DeltaTime) 
	{
// 		AngularMovement.AccelerateTo(TargetRotation, 1.f, DeltaTime);
		AngularMovement.SpringTo(TargetRotation, 5.f, 0.4f, DeltaTime);
		GetOwner().SetActorRotation(AngularMovement.Value);
	}

	void ExpandToOriginalScale(float DeltaTime) 
	{
		if (Scale.Value.Equals(TargetScale))
			return;

		float ExpansionTime = 4.5f;
// 		float ExpansionTime = 2.5f;

		// need to modify the speed based on how close we are to the target.
		const float DeltaDistance = FMath::Max(LinearMovement.Value.Z - TargetZ, 0.f);
		const float Threshold = SwitchToBuoyancy_DistanceThreshold * 4.f;
		if (Threshold > 0.f  && DeltaDistance <= Threshold)
		{
			const float Alpha = DeltaDistance / Threshold;
			ExpansionTime = FMath::Min(FMath::Lerp(0.f, ExpansionTime, Alpha), ExpansionTime);
		}

		Scale.AccelerateTo(TargetScale, ExpansionTime, DeltaTime);
		GetOwner().SetActorScale3D(Scale.Value);
	}

	void ApplySpringMovement(float DeltaTime)
	{
		FVector TargetLocation = LinearMovement.Value;
		TargetLocation.Z = TargetZ;
		LinearMovement.SpringTo(TargetLocation, Stiffness, Damping, DeltaTime);
		GetOwner().SetActorLocation(LinearMovement.Value);
	}

	float FindGroundZ() const
	{
		const FVector TraceStartLocation = GetOwner().GetActorLocation();

		FHitResult HitData;
		bool bHitSomething = System::LineTraceSingle(
			TraceStartLocation,
			TraceStartLocation - FVector::UpVector * 100000.f,
			ETraceTypeQuery::Visibility,
			false,
			IgnoreActors,
			EDrawDebugTrace::None,
			HitData,
			true
		);

		if (bHitSomething)
		{
			return HitData.ImpactPoint.Z;
		}

		// Should not be able to get here..
		ensure(false);
		return -1.f;
	}
}
