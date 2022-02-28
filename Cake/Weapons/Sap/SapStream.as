import Cake.Weapons.Sap.SapWeaponSettings;
import Cake.Weapons.Sap.SapWeaponAimStatics;
import Cake.Weapons.Sap.SapManager;

class USapProjectileEventHandler : UObjectInWorld
{

}

class USapStreamEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly)
	ASapStreamParticle Owner;

	void InitInternal(ASapStreamParticle Particle)
	{
		SetWorldContext(Particle);
		Owner = Particle;
		Init();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void Init() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnEnabled() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnDisabled() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnHitStickSurface(FSapAttachTarget Where) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnHitSap(ASapBatch Batch) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnHitNonStickSurface(FSapAttachTarget Where) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTick(float DeltaTime) {}
}

class USapStream : UObjectInWorld
{
	UPROPERTY(Category = "Particles")
	TSubclassOf<ASapStreamParticle> ParticleClass;
	TArray<ASapStreamParticle> Particles;

	USapManager SapManager;

	void Init(USapManager InSapManager)
	{
		SapManager = InSapManager;

		for(int i=0; i<Sap::Stream::NumParticles; i++)
		{
			ASapStreamParticle Particle = Cast<ASapStreamParticle>(SpawnActor(ParticleClass));
			Particles.Add(Particle);

			Particle.Init(InSapManager);
		}
	}

	void FireParticle(FVector Origin, FVector Velocity, FSapAttachTarget Target)
	{
		float BestEnableTime = 0.f;
		ASapStreamParticle BestParticle = nullptr;

		for(int i=0; i<Particles.Num(); ++i)
		{
			auto Particle = Particles[i];
			if (!Particle.bIsParticleEnabled)
			{
				BestParticle = Particle;
				break;
			}

			if (BestParticle == nullptr || BestEnableTime > Particle.EnableTime)
			{
				BestParticle = Particle;
				BestEnableTime = Particle.EnableTime;
			}
		}

		BestParticle.EnableParticle(Origin, Velocity, Target);
	}
}

class ASapStreamParticle : AHazeActor
{
	bool bIsParticleEnabled = false;
	FVector Velocity;
	FSapAttachTarget Target;
	float Lifetime = 0.f;

	FVector PrevParentLocation;

	USapManager SapManager;

	UPROPERTY(Category = "Events", EditDefaultsOnly)
	TArray<TSubclassOf<USapStreamEventHandler>> EventHandlerClasses;
	TArray<USapStreamEventHandler> EventHandlers;

	// Cumilitive offset of the thing we're shooting at (how much it moved since we fired)
	FVector LocationError;

	bool bSkipCollisionDelay;

	// Used for recycling stream particles
	float EnableTime = 0.f;

	void CallOnEnabledEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnEnabled();
	}
	void CallOnDisabledEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnDisabled();
	}
	void CallOnHitStickSurfaceEvent(FSapAttachTarget Where)
	{
		for(auto Handler : EventHandlers)
			Handler.OnHitStickSurface(Where);
	}
	void CallOnHitNonStickSurfaceEvent(FSapAttachTarget Where)
	{
		for(auto Handler : EventHandlers)
			Handler.OnHitNonStickSurface(Where);
	}
	void CallOnHitSapEvent(ASapBatch Batch)
	{
		for(auto Handler : EventHandlers)
			Handler.OnHitSap(Batch);
	}
	void CallOnTickEvent(float DeltaTime)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTick(DeltaTime);
	}

	void Init(USapManager Manager)
	{
		SapManager = Manager;
		DisableParticle();

		// Spawn up event handlers
		for(auto HandlerClass : EventHandlerClasses)
		{
			USapStreamEventHandler Handler = Cast<USapStreamEventHandler>(NewObject(this, HandlerClass));
			Handler.InitInternal(this);
			EventHandlers.Add(Handler);
		}
	}

	void EnableParticle(FVector Origin, FVector InVelocity, FSapAttachTarget InTarget)
	{
		SetActorTickEnabled(true);
		bIsParticleEnabled = true;

		SetActorLocation(Origin);
		SetActorHiddenInGame(false);
		Velocity = InVelocity;

		Lifetime = 0.f;
		Target = InTarget;
		LocationError = FVector::ZeroVector;
		EnableTime = Time::RealTimeSeconds;

		PrevParentLocation = Target.ParentTransform.Location;

		CallOnEnabledEvent();

		// If the target have overridden projectile speed, we skip the collision delay in case we're close enough
		bSkipCollisionDelay = false;
		if (InTarget.IsValid() && (InTarget.Actor != nullptr))
		{
			auto ResponseComp = USapResponseComponent::Get(InTarget.Actor);
			if (ResponseComp != nullptr)
			{
				bSkipCollisionDelay = ResponseComp.bOverrideSapSpeed;
			}
		}
	}

	void DisableParticle()
	{
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
		bIsParticleEnabled = false;

		CallOnDisabledEvent();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CallOnTickEvent(DeltaTime);

		// Accelerate!
		FVector Acceleration = -FVector::UpVector * Sap::Projectile::Gravity;
		FVector Delta = Velocity * DeltaTime + Acceleration * DeltaTime * DeltaTime * 0.5f;
		Velocity += Acceleration * DeltaTime;

		// HOMING YOOO
		// Check how much the thing we're aiming at has moved, so we can move with it
		// Only check with the parent transform location though, not with the attach-world-location
		// This makes it so that prediction doesn't care about the parent rotates, only how it moves
		FVector ParentLocation = Target.ParentTransform.Location;
		FVector ParentDelta = ParentLocation - PrevParentLocation;
		PrevParentLocation = ParentLocation;

		LocationError += ParentDelta;

		// Reduce the error!
		FVector CurrentForward = Velocity.GetSafeNormal();
		float DistanceToTarget = CurrentForward.DotProduct(ParentLocation - ActorLocation); 
		if (DistanceToTarget > 0.f)
		{
			float ErrorReductionRate = Math::Saturate(1.f - DistanceToTarget / Sap::Projectile::MaxErrorReductionDistance) * Sap::Projectile::MaxErrorReductionRate;
			FVector LocationErrorMoveDelta = LocationError.GetClampedToMaxSize(ErrorReductionRate * DeltaTime);

			Delta += LocationErrorMoveDelta;
			LocationError -= LocationErrorMoveDelta;
		}

		if (bSkipCollisionDelay || Lifetime > Sap::Stream::CollisionDelay)
		{
			// Are we hitting any existing sap?
			ASapBatch HitBatch = SapManager.FindBatchAtLocation(ActorLocation, Sap::Radius);
			if (HitBatch != nullptr)
			{
				SapManager.AddMassToBatch(HitBatch, 1.f);
				DisableParticle();

				CallOnHitSapEvent(HitBatch);
				return;
			}

			// Are we hitting any surfaces?
			FSapAttachTarget HitTarget = SapQueryRay(ActorLocation, ActorLocation + Delta, Sap::Radius, true);

			if (HitTarget.HasAttachParent())
			{
				ESapSpawnResult Result = SapManager.SpawnSapAtTarget(HitTarget, Sap::Projectile::Mass);
				switch(Result)
				{
					case ESapSpawnResult::Spawned:
					case ESapSpawnResult::MassAdded:
						CallOnHitStickSurfaceEvent(HitTarget);
						break;

					case ESapSpawnResult::NonStick:
						CallOnHitNonStickSurfaceEvent(HitTarget);
						break;

					case ESapSpawnResult::Consumed:
						// nothing for now...
						break;
				}

				DisableParticle();
				return;
			}
		}

		AddActorWorldOffset(Delta);

		Lifetime += DeltaTime;
		if (Lifetime > Sap::Projectile::MaxFlyTime)
		{
			DisableParticle();
		}
	}
}