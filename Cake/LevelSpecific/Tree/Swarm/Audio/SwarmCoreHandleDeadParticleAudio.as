import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

struct FSwarmCoreDeadParticleData
{	
	FVector Velocity;
	FVector Position;
	FVector PreviousTracedPosition;
	float Timer;
	FHazeAudioEventInstance StartInstance;
}

// Track 
class USwarmCoreDeadParticleAudioEffectManager : UActorComponent
{
	private TSet<USwarmCoreDeadParticleAudioEffect> ActiveEffects;

	TArray<FVector> CachedPositions;
	uint LastFrame = 0;
	bool bIntervalReset = true;

	int TotalActiveTrackedParticles;
	int TotalPostsThisFrame;

	int GetEffectCount()
	{
		return ActiveEffects.Num();
	}

	void Register(USwarmCoreDeadParticleAudioEffect Effect)
	{
		ActiveEffects.Add(Effect);
		if (ActiveEffects.Num() == 1)
			Reset::RegisterPersistentComponent(this);
	}

	void Unregister(USwarmCoreDeadParticleAudioEffect Effect)
	{
		ActiveEffects.Remove(Effect);
		if (ActiveEffects.Num() == 0)
			Reset::UnregisterPersistentComponent(this);
	}
}

// Reset::RegisterPersistentComponent(this);
class USwarmCoreDeadParticleAudioEffect : UHazeAudioEffect
{
	TArray<FSwarmCoreDeadParticleData> TrackedParticles;
	TArray<FAkSoundPosition> SoundPositions;

	TArray<AHazePlayerCharacter> Players;
	ASwarmActor SwarmActor;
	FSwarmCoreDeadParticleAudioSettings Settings;

	float IgnoreDistanceSquared = 0;
	float TimeSinceLastInterval = 0;

	TArray<FVector> CachedPositions;
	uint LastFrame = 0;
	int FrameSoundCount = 0;
	int MaxTracesPossible = 15;

	int TracedIndex = 0;
	int TraceIndex = 0;
	TArray<AActor> ActorsToIgnore;

	UHazeAsyncTraceComponent AsyncTraceComponent;
	FHazeTraceParams TraceParams;
	const FName AsyncTraceId = n"SwarmParticleAudioEffect";
	// Wait for the callback, due to issue with one swarm during level streaming.
	bool bTracing = false;

	USwarmCoreDeadParticleAudioEffectManager EffectManager;

	USwarmCoreDeadParticleAudioEffectManager GetAudioEffectManager()
	{
		if (EffectManager == nullptr)
			EffectManager = USwarmCoreDeadParticleAudioEffectManager::GetOrCreate(Game::GetMay());

		return EffectManager;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Players = Game::GetPlayers();

		for (auto Player: Players) 
		{
			ActorsToIgnore.Add(Player);
		}
		ActorsToIgnore.Add(HazeAkOwner.GetOwner());

		AsyncTraceComponent = UHazeAsyncTraceComponent::GetOrCreate(HazeAkOwner.Owner);
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		TraceParams.IgnoreActors(ActorsToIgnore);
		TraceParams.SetToLineTrace();

		GetAudioEffectManager().Register(this);
	}

	UFUNCTION()
	void SetupEvents(ASwarmActor SwarmActorOwner) 
	{
		SwarmActor = SwarmActorOwner;
		Settings = SwarmActor.SwarmCoreParticleAudioSettings;
		IgnoreDistanceSquared = FMath::Square(Settings.PrioritizeParticlesBelowDistance);
	}

	UFUNCTION()
	void Register(const FVector& Position, const FVector& Velocity) 
	{
		if (!bEnableEffect) 
		{
			SetEnabled(true);
		}

		auto Manager = GetAudioEffectManager();
		if (Time::FrameNumber - Manager.LastFrame >= Settings.IntervalFrameCount) 
		{
			Manager.bIntervalReset = true;
			Manager.CachedPositions.Reset();

			for (AHazePlayerCharacter Player : Players)
			{
				Manager.CachedPositions.Add(Player.GetActorLocation());
			}

			Manager.LastFrame = Time::FrameNumber;
			Manager.TotalActiveTrackedParticles = 0;
		}
		else {
			Manager.bIntervalReset = false;
		}

		if (Manager.bIntervalReset)
		{
			TimeSinceLastInterval = 0;
			FrameSoundCount = 0;
		}

		if (FrameSoundCount >= Settings.MaxParticlesToTracksPerInterval ||
			Manager.TotalActiveTrackedParticles >= Settings.MaxParticlesToTracksPerInterval * Manager.GetEffectCount())
			return;

		if (TimeSinceLastInterval < Settings.SkipPrioritizeCheckAfter &&
			TrackedParticles.Num() > Settings.PrioritizeToTrackAfterCount && 
			ShouldIgnoreNewParticle(Position, Velocity)) 
			return;

		FSwarmCoreDeadParticleData Data = FSwarmCoreDeadParticleData();
		Data.Position = Position;
		Data.PreviousTracedPosition = Position;
		Data.Velocity = Velocity;
		Data.Timer = 0;
		
		if (FrameSoundCount < Settings.MaxSoundsPerInterval) 
		{
			// When setting MultiplePositions we need to be detached from parent component to make sure it doesn't override sound position
			HazeAkOwner.DetachFromParent(true);
			Data.StartInstance = HazeAkOwner.HazePostEvent(SwarmActor.DeathParticleEvent);			
		}

		TrackedParticles.Add(Data);

		FAkSoundPosition AkPosition;
		AkPosition.SetPosition(Position);
		AkPosition.SetOrientation(FVector::ForwardVector, FVector::UpVector);
		SoundPositions.Add(AkPosition);

		++FrameSoundCount;
		++Manager.TotalActiveTrackedParticles;
	}

	bool ShouldIgnoreNewParticle(const FVector& Position, const FVector& Velocity)
	{
		FVector VelocityNormalized = Velocity;
		VelocityNormalized.Normalize();

		bool bIgnore = true;
		for (FVector Target : GetAudioEffectManager().CachedPositions)
		{
			FVector TargetDirection = Target - Position;
			if (TargetDirection.SizeSquared() < IgnoreDistanceSquared) 
			{
				bIgnore = false;
				break;
			}

			TargetDirection.Normalize();
			if (VelocityNormalized.DotProduct(TargetDirection) > .25)
			{
				bIgnore = false;
				break;
			}
		}

		return bIgnore;
	}

	UFUNCTION(BlueprintOverride)
	void TickEffect(float DeltaSeconds)
	{
		if (TrackedParticles.Num() == 0)
			return;

		TimeSinceLastInterval += DeltaSeconds;

		for (int i = TrackedParticles.Num() -1; i >= 0; --i)
		{
			FSwarmCoreDeadParticleData& Data = TrackedParticles[i];
			Data.Timer += DeltaSeconds;
			if (Data.Timer >= Settings.ParticleDuration)
			{
				StopInstance(i);
				continue;
			}

			FVector Velocity = Data.Velocity;
			Velocity.Z -= Settings.Gravity * DeltaSeconds;
			Data.Velocity = Velocity;
			FVector NewPosition = Data.Position + Velocity * DeltaSeconds;
			
			if (TraceIndex == i && !bTracing) 
			{
				TraceParams.From = Data.PreviousTracedPosition;
				TraceParams.To = NewPosition;
				TracedIndex = TraceIndex;
				bTracing = true;

				AsyncTraceComponent.TraceSingle(TraceParams, this, AsyncTraceId, 
					FHazeAsyncTraceComponentCompleteDelegate(this, n"OnAsyncTraceCompleted"));

				NextTrace();
			}
		
			Data.PreviousTracedPosition = Data.Position;
			Data.Position = NewPosition;
			// System::DrawDebugPoint(NewPosition, 5.0f, FLinearColor::White);
			TrackedParticles[i] = Data;
			SoundPositions[i].SetPosition(NewPosition);
		}

		HazeAkOwner.HazeSetMultiplePositions(SoundPositions, AkMultiPositionType::MultiDirections);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnAsyncTraceCompleted(UObject Instigator, FName TraceId, const TArray<FHitResult>& Obstructions)
	{
		bTracing = false;
		if (Obstructions.Num() == 0)
			return;

		auto Hit = Obstructions[0];
		if(Hit.bBlockingHit)
		{
			UHazeAkComponent::HazePostEventFireForget(SwarmActor.DeathParticleRicochet, FTransform(Hit.Location));	
			// if (Hit.bBlockingHit)
			// 	System::DrawDebugLine(Hit.TraceStart, Hit.TraceEnd, FLinearColor::Green, 1.f, 10.f);
		}

		// Mark for removal if possible.
		if (TrackedParticles.IsValidIndex(TracedIndex))
			TrackedParticles[TracedIndex].Timer +=Settings.ParticleDuration;
	}

	void NextTrace() 
	{
		++TraceIndex;
		if (TraceIndex >= TrackedParticles.Num() || TraceIndex >= MaxTracesPossible)
		{
			TraceIndex = 0;
		}
	}

	void StopInstance(int index) 
	{
		// If we remove a index smaller then TracedIndex, it needs an update.
		if (index < TracedIndex)
			--TracedIndex;
			
		if (index == TracedIndex)
			TracedIndex = -1;

		if (TrackedParticles[index].StartInstance.PlayingID != 0) 
		{
			HazeAkOwner.HazeStopEvent(TrackedParticles[index].StartInstance.PlayingID);
		}

		TrackedParticles.RemoveAt(index);
		SoundPositions.RemoveAt(index);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemove()
	{
		GetAudioEffectManager().Unregister(this);

		// Re-attach to owning swarm actor to reset multiple-positions
		auto OwnerRoot = HazeAkOwner.GetOwner().RootComponent;
		HazeAkOwner.AttachTo(OwnerRoot, AttachType = EAttachLocation::SnapToTarget);	
		
		if (TrackedParticles.Num() == 0)
			return;

		if (HazeAkOwner.bIsEnabled)
		{
			for (int i = TrackedParticles.Num() -1; i >= 0; --i)
			{
				StopInstance(i);
			}
		}
		
		TrackedParticles.Reset();
	}

	UFUNCTION()
	int GetTrackedParticleCount()
	{
		return TrackedParticles.Num();
	}

	UFUNCTION()
	int GetFrameCount()
	{
		return FrameSoundCount;
	}

}
