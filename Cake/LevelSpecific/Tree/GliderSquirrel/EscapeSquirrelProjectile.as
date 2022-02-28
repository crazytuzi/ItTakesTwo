import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachine;
import Peanuts.Audio.HazeAudioEffects.DopplerDataComponent;

class AEscapeSquirrelProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent)
	UDopplerDataComponent DopplerComp;

	UPROPERTY(Category = "Projectile", EditDefaultsOnly)
	float Speed = 10000.f;

	UPROPERTY(Category = "Projectile", EditDefaultsOnly)
	float Damage = 0.3f;

	default SetActorTickEnabled(false);

	bool bActive = false;

	AFlyingMachine TargetMachine;
	FVector InheritedVelocity;

	const float LifetimeDuration = 2.7f;
	const float FadeoutDuration = 0.4f;

	float TimeoutTimer;
	float AccumTime = 0.f;

	float FadeoutTimer = 0.4f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableActor(this);
		SetActorTickEnabled(false);
		AkComp.SetTrackDistanceToPlayer(true, Game::GetMay(), 10000.f);
	}

	UFUNCTION(BlueprintCallable)
	void InitializeProjectile(FVector Origin, FVector Direction, FVector InInheritedVelocity)
	{
		InheritedVelocity = InheritedVelocity;
		SetActorLocationAndRotation(Origin, Math::MakeQuatFromX(Direction));

		EnableActor(this);
		bActive = true;
		TimeoutTimer = LifetimeDuration;
		FadeoutTimer = FadeoutDuration;

		AccumTime = 0.f;

		BP_OnInitialized(Origin, Direction, InheritedVelocity);

	}

	void Deactivate()
	{
		bActive = false;
		DisableActor(this);
	}

	void UpdateMovement()
	{
		if (AccumTime == 0.f)
			return;

		// After timing out or hitting something, we want to give a brief time for effects to fade out before disabling
		// Otherwise the trails disappear in an ugly way
		if (TimeoutTimer <= 0.f)
		{
			FadeoutTimer -= AccumTime;
			if (FadeoutTimer <= 0.f)
				Deactivate();

			AccumTime = 0.f;
			return;
		}

		TArray<UPrimitiveComponent> ComponentsToTrace;
		if (TargetMachine != nullptr)
			ComponentsToTrace.Add(TargetMachine.ProjectileCollision);

		FVector Loc = GetActorLocation();
		FVector WorldDelta = (InheritedVelocity + ActorForwardVector * Speed) * AccumTime;

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		Trace.From = Loc;
		Trace.To = Loc + WorldDelta;

		FHazeHitResult Hit;
		Trace.ExclusiveTrace(ComponentsToTrace, Hit);

		if (Hit.FHitResult.bBlockingHit)
		{
			if (Hit.Actor != nullptr)
			{
				auto FlyingMachine = Cast<AFlyingMachine>(Hit.Actor);
				if (FlyingMachine != nullptr)
				{
					FlyingMachine.TakeDamage(Damage);
				}
			}

			BP_OnHit(Hit.FHitResult);

			TimeoutTimer = 0.f;
			AccumTime = 0.f;
			return;
		}

		else
		{
			AddActorWorldOffset(WorldDelta);
		}

		// Calculate how relevant this projectile is to the game
		// If its going away or something make it go away faster to free up the pool

		// If we're going "alongside" the machine, behind or in front
		float FollowingRelevancy = ActorForwardVector.DotProduct(TargetMachine.ActorForwardVector);

		// If we're going towards the machine, from the front or behind
		FVector ToMachine = TargetMachine.ActorLocation - ActorLocation;
		ToMachine.Normalize();
		float DirectionalRelevancy = ActorForwardVector.DotProduct(ToMachine);

		// If either of these two cases are true, we are considered "relevant"
		float Relevancy = FMath::Max(FollowingRelevancy, DirectionalRelevancy);
		float DecayScale = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 1.f), FVector2D(2.4f, 0.8f), Relevancy);

		TimeoutTimer -= AccumTime * DecayScale;
		AccumTime = 0.f;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnInitialized(FVector Origin, FVector Direction, FVector InheritedVelocity)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnHit(FHitResult Hit)
	{
	}
}