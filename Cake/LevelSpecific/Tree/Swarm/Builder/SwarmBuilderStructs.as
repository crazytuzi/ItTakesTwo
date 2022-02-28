import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

struct FBuilderEntity
{
	UPROPERTY()
	FName AssignedBoneName = NAME_None;

	UPROPERTY()
    FVector Location = FVector::ZeroVector;

	UPROPERTY()
    FVector Velocity = FVector::ZeroVector;

	UPROPERTY()
    FVector DesiredLocation = FVector::ZeroVector;

	UPROPERTY()
    FVector DesiredDirection = FVector::ZeroVector;

	UPROPERTY()
	FRotator Rotation = FRotator::ZeroRotator;
//	FQuat Rotation = FQuat::Identity;

    float TimeSinceActivation = 0.f;
    float DistanceAlongSpline = 0.f;

    void ResetInitialTransientValues()
    {
		// Location should be set before calling this function
		ensure(Location != FVector::ZeroVector);

        TimeSinceActivation = 0;
        DistanceAlongSpline = 0;
        DesiredLocation = Location;
        Velocity = FVector::ZeroVector;
    } 

	void UpdateRotation()
	{
		Rotation = DesiredDirection.ToOrientationRotator();
//		Rotation = DesiredDirection.ToOrientationQuat();
	}

    void StayOrthogonalToDesired()
    {
		// ensure we are orthogonal to desired dir. Always.
		FVector ClosestPointOnLine = DesiredLocation;
		const float DistOnLine = (Location - DesiredLocation).DotProduct(DesiredDirection);
		ClosestPointOnLine += DesiredDirection * DistOnLine;
		const FVector Offset = Location - ClosestPointOnLine;
		Location = DesiredLocation + Offset;
    }

	void SteerToTarget(
		const float Dt,
		const float MaxSpeed = 5000.f,
		const float MaxForce = 2500.f 
	)
	{
		// steering acceleration
		FVector Acceleration = (DesiredDirection * MaxSpeed) - Velocity;
		Acceleration = Acceleration.GetClampedToMaxSize(MaxForce);
		Velocity += Acceleration * Dt;
		Location += Velocity * Dt;
	}

    void SpringToDesired(float Stiffness, float Damping, float Dt)
    {
		const float IdealDampingValue = 2.f * FMath::Sqrt(Stiffness);
		const FVector ToUs = Location - DesiredLocation;
		Velocity -= (ToUs*Dt*Stiffness);
		Velocity /= (1.f + (Dt*Dt*Stiffness) + (Damping*IdealDampingValue*Dt));
		//Velocity = Velocity.VectorPlaneProject(DesiredDirection);
        Location += (Velocity * Dt);
    }

    void AccelerateToDesired(float Duration, float Dt)
    {
        if(FMath::IsNearlyZero(Duration))
        {
            ensure(false);
            return;
        }

		const float LAMBERT_NOMINATOR = 9.23341f; // Within 0.1%; 1% is 6.63835
		const float Acceleration = LAMBERT_NOMINATOR / Duration;
		const FVector ToTarget = DesiredLocation - Location;

		Velocity += ToTarget * FMath::Square(Acceleration) * Dt;
		Velocity /= FMath::Square(1.f + Acceleration * Dt);
        Location += (Velocity * Dt);
    }

//    void AddNoise(float NoiseScale, float NoiseGain, float Dt)
//    {
//        Velocity += (Noise::GetCurlNoise(Location, NoiseScale, NoiseGain) / Dt);
//    }

};

struct FBuilderSplineNetworkData
{
	// identifier
	int BuilderSplineIdentifierIndex = -1;

	// Queued entities that should be activated
	int NumEntitiesToRelease = 0;
};

struct FBuilderSpline
{
    // The actual builder spline associated with this struct
    USplineComponent Spline;

    // Swarm mesh being built
    UHazeSwarmSkeletalMeshComponent Mesh; 

    // Until we release new Entities by rotating the arrays. 
	// float TimeSinceRelease = BIG_NUMBER;
	float TimeSinceRelease = 0.f;
 
    // All Entities assigned to this spline.
	UPROPERTY()
    TArray<FBuilderEntity> AssignedEntities;
	float AssignedEntitiesFactor = 1.f;

    // Entities currently riding the spline
	UPROPERTY()
    TArray<FBuilderEntity> ActiveEntities;

    // Entities that will replace the active ones, once they are done.
	UPROPERTY()
    TArray<FBuilderEntity> QueuedEntities; 

    // Entities that have been replaced by the swarm bones.
	UPROPERTY()
    TArray<FBuilderEntity> FinishedEntities; 

	float DEBUG_TimeStamp_FinalFinished = 0.f;
	float DEBUG_TimeStamp_AllActive = 0.f;
	float DEBUG_TimeElapsed = 0.f;

	// we want to find a good value here that ensures 
	// that we don't spawn multiple wasps the same frame
	const float MinTimeBetweenRelease = 1.f / 200.f;
	// const float MinTimeBetweenRelease = 0.05f;

	float TimeBetweenEntityReleases = -1.f;

	void UpdateTimeBetweenReleasesAndEntitySpeed(float InBuildTime)
	{
		// default speed used when there is no specific build time specified
		EntitySpeedOnSpline = InitalEntitySpeedOnSpline;
		// EntitySpeedOnSpline = 2500.f;

		// flag that we don't want to release any entities initially
		TimeBetweenEntityReleases = -1.f;

		// early out. We've reached the desired amount of swarms
		if (InBuildTime < 0.f)
			return;

		const float NumAssignedEntities = AssignedEntities.Num();
		const float SplineLength = Spline.GetSplineLength();

		float SpaceBetweenParticles = Mesh.ParticleRadius * 2.f;
		SpaceBetweenParticles += PaddingBetweenParticles;
		const float MinWaspTrailLength = NumAssignedEntities * SpaceBetweenParticles;
		const float MinTotalReleaseTime = MinWaspTrailLength / EntitySpeedOnSpline;
		// const float MinTotalReleaseTime = MinTimeBetweenRelease * NumAssignedEntities;

		if(InBuildTime > MinTotalReleaseTime)
		{
			float RemainingTime = InBuildTime;
			RemainingTime -= MinTotalReleaseTime;

			TimeBetweenEntityReleases = MinTotalReleaseTime;

			const float DesiredTravelTime = SplineLength / EntitySpeedOnSpline;
			if(DesiredTravelTime < RemainingTime)
			{
				// we got to keep the desired travel time
				RemainingTime -= DesiredTravelTime;
				TimeBetweenEntityReleases += RemainingTime;
			}
			else
			{
				// change speed on spline.
				EntitySpeedOnSpline = SplineLength / RemainingTime;
				// PrintToScreen("New Speed on Spline: " + EntitySpeedOnSpline);
			}

			TimeBetweenEntityReleases *= AssignedEntitiesFactor;
		}
		else if(InBuildTime == 0.f)
		{
			TimeBetweenEntityReleases = SMALL_NUMBER;
			EntitySpeedOnSpline = BIG_NUMBER;
		}
		else
		{
			// we'll just split the time in half.
			const float HalfBuildTime = InBuildTime * 0.5f;
			EntitySpeedOnSpline = SplineLength / HalfBuildTime;
			TimeBetweenEntityReleases = HalfBuildTime * AssignedEntitiesFactor;
		}
	}

	bool ShouldProcessEntityQueue() 
	{
		if(TimeBetweenEntityReleases < 0.f)
			return false;

        if(QueuedEntities.Num() <= 0)
            return false;

		return true;
	}

    void ProcessEntityQueue(int& OutNumEntitiesToRelease, float Dt)
	{
		ensure(OutNumEntitiesToRelease == 0);

		TimeSinceRelease += Dt;

		int NumQueuedEntities = QueuedEntities.Num();

		while(TimeSinceRelease >= TimeBetweenEntityReleases)
		{
			if(NumQueuedEntities <= 0)
				break;

			++OutNumEntitiesToRelease;
			--NumQueuedEntities;

			TimeSinceRelease -= TimeBetweenEntityReleases;
		}

		// Spit out one entity immediately upon build start
		// if(QueuedEntities.Num() == AssignedEntities.Num() 
		// && OutNumEntitiesToRelease == 0
		// && ActiveEntities.Num() == 0)
		// {
		// 	++OutNumEntitiesToRelease;
		// 	--NumQueuedEntities;
		// }

	}

    void UpdateEntityQueue(float TimeBetweenReleases, float Dt)
    {
		if(TimeBetweenReleases < 0.f)
			return;

        if(QueuedEntities.Num() <= 0)
            return;

		TimeSinceRelease += Dt;

		while(TimeSinceRelease >= TimeBetweenReleases)
		{
			if(QueuedEntities.Num() <= 0)
				break;

            ReleaseQueuedEntity(0);
			TimeSinceRelease -= TimeBetweenReleases;
		}
    }

    void ReleaseQueuedEntity(int Index)
    {
        if(QueuedEntities.Num() <= 0)
        {
            ensure(false);
            return;
        }

        QueuedEntities[Index].Location = Spline.GetLocationAtDistanceAlongSpline(
            0,//Spline.GetSplineLength(),
            ESplineCoordinateSpace::World
        );

        // Update initial values for the entity
        QueuedEntities[Index].ResetInitialTransientValues();

        ActiveEntities.Add(QueuedEntities[Index]);
        QueuedEntities.RemoveAt(Index);
    }

    void Reset()
    {
        FinishedEntities.Reset();

		ActiveEntities.Reset();
		QueuedEntities.Reset();

		for(int i = 0; i < AssignedEntities.Num(); ++i)
		{
			AssignedEntities[i].ResetInitialTransientValues();
			QueuedEntities.Add(AssignedEntities[i]);
		}

		TimeSinceRelease = 0.f;

		PaddingBetweenParticles = FMath::RandRange(200.f, 400.f);
		InitalEntitySpeedOnSpline = FMath::RandRange(1500.f, 3000.f);
		EntitySpeedOnSpline = InitalEntitySpeedOnSpline;
    }

	float PaddingBetweenParticles = FMath::RandRange(200.f, 400.f);
	float InitalEntitySpeedOnSpline = FMath::RandRange(1500.f, 3000.f);
	float EntitySpeedOnSpline = InitalEntitySpeedOnSpline;
	// float EntitySpeedOnSpline = 2500.f;

	const float IncomingSpeed = 1100.f;

    void RetireActiveEntity(int Index)
    {
        if(ActiveEntities.Num() <= 0)
        {
            ensure(false);
            return;
        }

		const FBuilderEntity FinishedEntity = ActiveEntities[Index]; 
		const FName BoneName = FinishedEntity.AssignedBoneName; 

		//////////////////////////////////////////////////////
		// @TODO: move to swarm and ensure that this 
		// doesn't trigger more than once per frame...

		ASwarmActor Swarm = Cast<ASwarmActor>(Mesh.Owner);
		ensure(!Swarm.IsAboutToDie());
		Mesh.ReviveParticleByBoneName(BoneName);

        const FVector BoneLoc = Swarm.SkelMeshComp.GetSocketLocation(BoneName);

		const int32 ParticleIndex = Swarm.SkelMeshComp.GetParticleIndexByName(BoneName);
		const FSwarmParticle& ParticleData = Swarm.SkelMeshComp.Particles[ParticleIndex];

		// const FVector ParticleLoc = Swarm.SkelMeshComp.Particles[ParticleIndex].CurrentTransform.GetLocation();
		// const FVector DeltaMove = FinishedEntity.Location - ParticleLoc; 
		// Swarm.SkelMeshComp.ApplyDeltaTranslationToParticleByIndex(ParticleIndex, DeltaMove);
		Swarm.SkelMeshComp.SetParticleLocationByIndex(ParticleIndex, FinishedEntity.Location);
		Swarm.SkelMeshComp.SetParticleRotationByIndex(ParticleIndex, FinishedEntity.Rotation.Quaternion());

		// inheriting the velocity will make it harder to tell what shape it is creating
		// Swarm.SkelMeshComp.Particles[ParticleIndex].Velocity = FinishedEntity.Velocity;

		FVector ForcePos = FinishedEntity.Location;

		FSwarmForceField RadialImpulseSettings;
		RadialImpulseSettings.Radius = 250.f;
		RadialImpulseSettings.Strength = IncomingSpeed;
		RadialImpulseSettings.bLinearFalloff = true;
		Mesh.AddForceFieldVelocity(ForcePos, RadialImpulseSettings);
		// System::DrawDebugSphere(ForcePos, RadialImpulseSettings.Radius, LineColor = FLinearColor::White, Duration = 1.f);

		const FVector FinishedVelocityNormalized = FinishedEntity.Velocity.GetSafeNormal();

		RadialImpulseSettings.Radius *= 0.8f;
		ForcePos += (FinishedVelocityNormalized * RadialImpulseSettings.Radius); 
		// System::DrawDebugSphere(ForcePos, RadialImpulseSettings.Radius, LineColor = FLinearColor::Yellow, Duration = 1.f);
		Mesh.AddForceFieldVelocity(ForcePos, RadialImpulseSettings);

		ForcePos += (FinishedVelocityNormalized * RadialImpulseSettings.Radius); 
		RadialImpulseSettings.Radius *= 0.8f;
		// System::DrawDebugSphere(ForcePos, RadialImpulseSettings.Radius, LineColor = FLinearColor::Green, Duration = 1.f);
		Mesh.AddForceFieldVelocity(ForcePos, RadialImpulseSettings);

		ForcePos += (FinishedVelocityNormalized * RadialImpulseSettings.Radius); 
		RadialImpulseSettings.Radius *= 0.8f;
		// System::DrawDebugSphere(ForcePos, RadialImpulseSettings.Radius, LineColor = FLinearColor::Blue, Duration = 1.f);
		Mesh.AddForceFieldVelocity(ForcePos, RadialImpulseSettings);

		// System::DrawDebugArrow(BoneLoc, BoneLoc + FinishedVelocityNormalized * 1000.f, Duration = 1.f);

		// remove the force field impulse from this particle.
		Swarm.SkelMeshComp.AddVelocityToParticleByBoneName(BoneName, -ParticleData.AccumulatedVelocities);
		Swarm.SkelMeshComp.AddVelocityToParticleByBoneName(BoneName, FinishedVelocityNormalized * IncomingSpeed);

		//////////////////////////////////////////////////////

        ActiveEntities[Index].ResetInitialTransientValues();
        FinishedEntities.Add(ActiveEntities[Index]);
        ActiveEntities.RemoveAt(Index);
    }

	void UpdateActiveEntities(float Dt)
	{
		for (int i = ActiveEntities.Num() - 1; i >= 0; i--)
		{
			FBuilderEntity& Entity = ActiveEntities[i];

			const FVector BoneLoc = Mesh.GetSocketLocation(Entity.AssignedBoneName);
			float DistToBoneSQ = (BoneLoc - Entity.Location).SizeSquared();
			// float DistToBoneSQ = (Mesh.CenterOfParticles - Entity.Location).SizeSquared();

			const float SpringToBoneThreshold = Mesh.GetLocalBoundsRadius();
			bool bReachedEndOfSpline = Entity.DistanceAlongSpline >= Spline.GetSplineLength();
			// if(false)
			if (DistToBoneSQ < FMath::Square(SpringToBoneThreshold) || bReachedEndOfSpline)
			{
				Entity.DesiredDirection = (BoneLoc - Entity.Location).GetSafeNormal();
				Entity.DesiredLocation = FMath::VInterpConstantTo(Entity.Location, BoneLoc, Dt, EntitySpeedOnSpline);
			}
			else
			{
				Entity.DistanceAlongSpline += EntitySpeedOnSpline*Dt;

				Entity.DesiredLocation = Spline.GetLocationAtDistanceAlongSpline(
					Entity.DistanceAlongSpline,
					ESplineCoordinateSpace::World
				);

				Entity.DesiredDirection = Spline.GetTangentAtDistanceAlongSpline(
					Entity.DistanceAlongSpline,
					ESplineCoordinateSpace::World
				).GetSafeNormal();
			}

			const float Stiffness = 50.f;
			const float Damping = 0.6f;
			Entity.SpringToDesired(
				(FMath::RandRange(0.f, Stiffness) * 0.8f) + (Stiffness * 0.2f),
				Damping,
				Dt
			);

			Entity.StayOrthogonalToDesired();
			Entity.UpdateRotation();

			// update distance after move
			DistToBoneSQ = (BoneLoc - Entity.Location).SizeSquared();

			// disable the entity if it's close enough to the bone
			// visually this controls how fast they seem to hit the swarm as they come in. 
			const float RetireEntityThreshold = Mesh.ParticleRadius;
			// if(bReachedEndOfSpline)
			if (DistToBoneSQ < FMath::Square(RetireEntityThreshold))
			{
				RetireActiveEntity(i);
				continue;
			}
		}
	}

};
