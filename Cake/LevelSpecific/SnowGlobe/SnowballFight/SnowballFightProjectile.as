import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerDataComponent;
import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightNames;

event void FSnowballHitSignature(FHitResult Hit);
event void FSnowballActivatedSignature(ASnowballFightProjectile Projectile);
event void FSnowballDeactivatedSignature(ASnowballFightProjectile Projectile);

class ASnowballFightProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshComponent;
	default StaticMeshComponent.bHiddenInGame = true;
	default StaticMeshComponent.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UNiagaraComponent TrailEffectComponent;
	default TrailEffectComponent.bAutoActivate = false;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
	UDopplerDataComponent DopplerDataComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Projectile")
	float MaxDuration = 10.f;
	UPROPERTY(Category = "Projectile")
	float Speed = 7500.f;
	UPROPERTY(Category = "Projectile")
	FVector Gravity = FVector(0.f, 0.f, -980.f);
	UPROPERTY(Category = "Projectile")
	float CurveHeight = 1000.f;
	UPROPERTY(Category = "Projectile")
	float CollisionGracePeriod = 0.02f;
	UPROPERTY(Category = "Projectile")
	float NoHomingDistance = 300.f;
	UPROPERTY(Category = "Projectile")
	float TrailDissipationTime = 1.f;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem HitEffect;
	UPROPERTY(Category = "VFX")
	UNiagaraSystem TrailEffect;

	UPROPERTY(Category = "Events", meta = (NotBlueprintCallable))
	FSnowballHitSignature OnSnowballHit;
	UPROPERTY(Category = "Events", meta = (NotBlueprintCallable))
	FSnowballActivatedSignature OnSnowballActivated;
 	UPROPERTY(Category = "Events", meta = (NotBlueprintCallable))
	FSnowballDeactivatedSignature OnSnowballDeactivated;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartPassByLoopEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopPassByLoopEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SnowBallGenericImpact;
	
	AActor ProjectileOwner;	
	float ExpirationTime;
	float GraceEndTime;
	float DisableTime;

	FSnowballFightTargetData TargetData;
	ASnowfolkSplineFollower TargetSnowFolk;
	FVector LinearLocation;
	FVector Velocity;
	float ThrowPower;
	float ThrowDistance;
	bool bIsHoming;

	// Fire & forget type snowballs for snowfolk
	bool bAutoDestroy;

	private bool bIsDeactivating;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TrailEffectComponent.SetAsset(TrailEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Wait for trail dissipation before disabling fully
		if (bIsDeactivating)
		{
			if (Time::GameTimeSeconds > DisableTime)
			{
				SetActorTickEnabled(false);
				DisableActor(this);

				OnSnowballDeactivated.Broadcast(this);

				OnSnowballHit.Clear();
				OnSnowballActivated.Clear();
				OnSnowballDeactivated.Clear();

				if (bAutoDestroy)
					DestroyActor();
			}
			return;
		}

		// Expiration date!
		if (Time::GameTimeSeconds > ExpirationTime)
		{
			Deactivate();
			return;
		}

		// Apply homing if we're homing, otherwise apply gravity
		if (bIsHoming)
		{
			const FVector ToTarget = (TargetData.GetWorldLocation() - ActorLocation);

			// Disable homing if we're too close, retaining curved velocity
			// otherwise keep moving towards the target
			if (ToTarget.Size() <= NoHomingDistance)
			{
				bIsHoming = false;
				LinearLocation = ActorLocation;
				Velocity = Math::SlerpVectorTowards(Velocity, ToTarget.GetSafeNormal(), 1.f);
			}
			else
			{
				const FVector ToTargetLinear = (TargetData.GetWorldLocation() - LinearLocation);
				Velocity = Math::SlerpVectorTowards(Velocity, ToTargetLinear.GetSafeNormal(), 1.f);
			}
		}
		else
		{
			Velocity += (FVector::UpVector * Gravity * DeltaTime);
		}

		// Contains our location without curve offset
		LinearLocation += (Velocity * DeltaTime);

		const FVector NextLocation = LinearLocation + GetCurveOffset(LinearLocation);

		if (Time::GameTimeSeconds > GraceEndTime)
		{
			// Check if we've passed our target snowfolk
			if (TargetSnowFolk != nullptr)
			{
				FVector ConstrainedLocation;
				TargetSnowFolk.Collision.GetClosestPointOnCollision(ActorLocation, ConstrainedLocation);

				const FVector ToSnowFolk = (ConstrainedLocation - NextLocation).GetSafeNormal();
				const FVector TravelDirection = (NextLocation - ActorLocation).GetSafeNormal();

				if (ToSnowFolk.DotProduct(-TravelDirection) > 0.f)
				{
					// Lego hit result, don't step on it
					FHitResult Hit = FHitResult(TargetSnowFolk, 
						TargetSnowFolk.Collision, 
						ConstrainedLocation, 
						-TravelDirection);

					ProjectileHit(Hit);
					return;
				}
			}

			FHazeTraceParams Trace;
			Trace.From = ActorLocation;
			Trace.To = NextLocation;
			Trace.SetToLineTrace();
			Trace.InitWithTraceChannel(ETraceTypeQuery::Visibility);
			Trace.IgnoreActor(ProjectileOwner, true);

			FHazeHitResult Hit;
			if (Trace.Trace(Hit) && Hit.bBlockingHit)
			{
				ProjectileHit(Hit.FHitResult);
				return;
			}
		}

		ActorLocation = NextLocation;
	}
	
	void Launch(float Range, FVector LaunchLocation, const FSnowballFightTargetData& InTargetData)
	{
		// Need to call activate before calling launch
		if (bIsDeactivating || IsActorDisabled())
			return;

		// Detach and move to launch location; should be synced from control
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		ActorLocation = LaunchLocation;
		LinearLocation = LaunchLocation;

		TargetData = InTargetData;
		TargetSnowFolk = (TargetData.Component != nullptr ? Cast<ASnowfolkSplineFollower>(TargetData.GetActor()) : nullptr);

		const FVector ToTarget = (TargetData.GetWorldLocation() - LaunchLocation);
		
		Velocity = ToTarget.GetSafeNormal() * Speed;
		ThrowDistance = ToTarget.Size();
		ThrowPower = ThrowDistance / Range;
		bIsHoming = ThrowDistance > NoHomingDistance;

		// Timestamp for grace period end, ignores collisions for duration
		GraceEndTime = (Time::GameTimeSeconds + CollisionGracePeriod);

		SetActorTickEnabled(true);

		if (InTargetData.bIsWithinCollision)
		{
			FHitResult Hit;
			Hit.ImpactPoint = ActorLocation;
			ProjectileHit(Hit);
		}
	}

	void Activate(AActor OwningActor, FName AttachSocketName = NAME_None)
	{
		ProjectileOwner = OwningActor;
		ExpirationTime = Time::GameTimeSeconds + MaxDuration;

		StaticMeshComponent.SetHiddenInGame(false);
		AttachToActor(OwningActor, AttachSocketName, EAttachmentRule::SnapToTarget);
		EnableDoppler();

		TrailEffectComponent.Activate();
		HazeAkComp.HazePostEvent(StartPassByLoopEvent);

		if (IsActorDisabled(this))
			EnableActor(this);

		bIsDeactivating = false;
		DisableTime = 0.f;

		OnSnowballActivated.Broadcast(this);
		OnSnowballActivated.Clear();
	}

	void Deactivate(bool bInstantDisable = false)
	{
		StaticMeshComponent.SetHiddenInGame(true);
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		DisableDoppler();

		TrailEffectComponent.Deactivate();
		HazeAkComp.HazePostEvent(StopPassByLoopEvent);

		bIsDeactivating = true;
		DisableTime = (bInstantDisable ? Time::GameTimeSeconds : Time::GameTimeSeconds + TrailDissipationTime);

		if (bInstantDisable)
		{
			SetActorTickEnabled(false);
			
			if (!IsActorDisabled(this))
				DisableActor(this);

			OnSnowballDeactivated.Broadcast(this);
			OnSnowballDeactivated.Clear();
		}
	}

	private void ProjectileHit(FHitResult Hit)
	{
		ActorLocation = Hit.ImpactPoint;
		PlayEffects();
		Deactivate();

		FHazeDelegateCrumbParams Params;
		Params.AddVector(n"HitVelocity", Velocity);
		Params.AddStruct(n"HitResult", Hit);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ProjectileHit"),
			Params);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_ProjectileHit(const FHazeDelegateCrumbData& CrumbData)
	{
		FVector HitVelocity = CrumbData.GetVector(n"HitVelocity");

		FHitResult Hit;
		CrumbData.GetStruct(n"HitResult", Hit);

		if (Hit.Actor != nullptr)
		{
			auto ResponseComponent = USnowballFightResponseComponent::Get(Hit.Actor);

			if (ResponseComponent != nullptr && ResponseComponent.bCanTakeDamage)
			{
				ResponseComponent.OnSnowballHit.Broadcast(ProjectileOwner,
					Hit, HitVelocity);

				for (FDopplerPassbyEvent PassbyEvent : DopplerDataComp.PassbyEvents)
					DopplerDataComp.DopplerInstance.StopPlayingPassbySound(PassbyEvent.Event);
			}
		}

		OnSnowballHit.Broadcast(Hit);
		OnSnowballHit.Clear();
	}
	
	private FVector GetCurveOffset(FVector Location) const
	{
		if (!bIsHoming)
			return FVector::ZeroVector;

		const float LinearDistance = (TargetData.GetWorldLocation() - Location).Size();
		const float Alpha = FMath::Sin((LinearDistance / ThrowDistance) * PI);
		
		return FVector::UpVector * CurveHeight * FMath::Pow(ThrowPower, 3.f) * Alpha;
	}

	private void EnableDoppler()
	{
		AHazePlayerCharacter OwningPlayer = Cast<AHazePlayerCharacter>(ProjectileOwner);
		if (OwningPlayer == nullptr)
			return;

		DopplerDataComp.DopplerInstance.SetEnabled(true);
		EHazeDopplerObserverType PlayerTarget = OwningPlayer.IsMay() ? EHazeDopplerObserverType::Cody : EHazeDopplerObserverType::May;
		DopplerDataComp.DopplerInstance.SetObjectDopplerValues(true, DopplerDataComp.MaxSpeed, DopplerDataComp.MinDistance, DopplerDataComp.MaxDistance, 
			DopplerDataComp.Scale, DopplerDataComp.Smoothing, DopplerDataComp.CurvePower, Observer = PlayerTarget);

		DopplerDataComp.DopplerInstance.ToggleAllPassbySounds(true);
		DopplerDataComp.DopplerInstance.bDebug = false;
	}

	private void DisableDoppler()
	{
		DopplerDataComp.DopplerInstance.SetEnabled(false);
	}

	private void PlayEffects()
	{
		Niagara::SpawnSystemAtLocation(HitEffect, ActorLocation);
		HazeAkComp.HazePostEvent(SnowBallGenericImpact, n"SnowBallGenericImpact");
	}
};