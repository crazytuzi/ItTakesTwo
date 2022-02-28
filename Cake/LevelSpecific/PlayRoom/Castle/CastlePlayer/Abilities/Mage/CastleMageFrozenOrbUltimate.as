import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;
import Vino.Time.ActorTimeDilationStatics;
import Cake.Environment.BreakableComponent;
import Peanuts.Audio.AudioStatics;

UCLASS(Abstract)
class ACastleMageFrozenOrbUltimate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent OrbCollider;
	default OrbCollider.RelativeScale3D = FVector(0.1f);
	default OrbCollider.SphereRadius = 100.f;
	default OrbCollider.CollisionProfileName = n"IgnorePlayerCharacter"; 

	UPROPERTY(DefaultComponent, Attach = OrbCollider)
	USphereComponent DamageCollider;
	default DamageCollider.SphereRadius = 400.f;
	default DamageCollider.CollisionProfileName = n"OverlapOnlyPawn";

	UPROPERTY(DefaultComponent)
	UNiagaraComponent OrbEffect;
	default OrbEffect.SetActive(false);

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	AHazePlayerCharacter OwningPlayer;
	UCastleComponent OwningPlayerCastleComponent;

	UPROPERTY()
	float StartSpeed = 1400.f;

	UPROPERTY()
	float DamageSpeed = 300.f;

	UPROPERTY()
	float UltimateSpendRate = 50.f;
	UPROPERTY()
	float UltimateSpendRateIncrease = 50.f;

	bool bMoveAtDamageSpeed = false;

	UPROPERTY()
	float Duration = 6.f;
	float DurationCurrent = Duration;

	float TickInterval = 0.33f;
	float DamagePerTick = 11.f;

	TArray<FCastleHitTimer> OrbDamageTargets;
	
	UPROPERTY()
	FHazeTimeLike StartOrbGrowthTimelike;
	default StartOrbGrowthTimelike.Duration = 0.5f;

	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;
	UPROPERTY()
	UAkAudioEvent DeactivateAudioEvent;
	UPROPERTY()
	UAkAudioEvent EnemyHitAudioEvent;
	UPROPERTY()
	UAkAudioEvent BounceAudioEvent;
	UPROPERTY()
	UAkAudioEvent DestroyedAudioEvent;
	UPROPERTY()
	UAkAudioEvent ReducedSpeedAudioEvent;
	UPROPERTY()
	UAkAudioEvent IncreasedSpeedAudioEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnDamageColliderBeginOverlap");
		DamageCollider.OnComponentEndOverlap.AddUFunction(this, n"OnDamageColliderEndOverlap");
		
		StartOrbGrowthTimelike.BindUpdate(this, n"OnStartOrbGrowthTimelike");
		StartOrbGrowthTimelike.PlayFromStart();

		PlayAudioEventFromComponent(ActivatedAudioEvent);
	}	

	UFUNCTION()
	void OnStartOrbGrowthTimelike(float CurrentValue)
	{
		FVector NewScale = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.1f, 1.f), CurrentValue);
		OrbCollider.SetRelativeScale3D(NewScale);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MoveOrb(DeltaTime);
		DamageEnemies(DeltaTime);
		IncreaseUltimateDecay(DeltaTime);
		SpendUltimateCharge(DeltaTime);
		ReduceDuration(DeltaTime);		
	}

	void MoveOrb(float DeltaTime)
	{	
		FVector MoveDirection = ActorForwardVector.ConstrainToPlane(FVector::UpVector);
		MoveDirection.Normalize();

		FVector DeltaMove = MoveDirection * (bMoveAtDamageSpeed ? DamageSpeed : StartSpeed) * DeltaTime;

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(this);
		//ActorsToIgnore.Add(Game::GetMay)
		FHitResult Hit;

		System::SphereTraceSingleByProfile(ActorLocation, ActorLocation + DeltaMove, OrbCollider.SphereRadius, n"IgnorePlayerCharacter", false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

		if (Hit.bBlockingHit)
		{		
			FVector NewDirection = FMath::GetReflectionVector(ActorForwardVector, Hit.Normal);	
			SetActorRotation(Math::MakeRotFromX(NewDirection));
			DeltaMove = (Hit.Location - ActorLocation) + NewDirection.GetSafeNormal();
			AddActorWorldOffset(DeltaMove);

			PlayAudioEvent(BounceAudioEvent);
		}
		else
			AddActorWorldOffset(DeltaMove);
	}

	void DamageEnemies(float DeltaTime)
	{
		for (int Index = OrbDamageTargets.Num() - 1; Index >= 0; Index--)
		{
			FCastleHitTimer& OrbDamageTarget = OrbDamageTargets[Index];
			OrbDamageTarget.Duration -= DeltaTime;

			if (OrbDamageTarget.Duration <= 0)
			{				
				OrbDamageTarget.Duration += TickInterval;

				PlayAudioEventAtActor(EnemyHitAudioEvent, OrbDamageTarget.CastleEnemy);
				DamageEnemy(OrbDamageTarget.CastleEnemy);

				// Dont do anything after this because the enemy might be removed from the list if it died = crash
			}
		}
	}

	void IncreaseUltimateDecay(float DeltaTime)
	{
		UltimateSpendRate += UltimateSpendRateIncrease * DeltaTime;
	}

	void SpendUltimateCharge(float DeltaTime)
	{
		if (OwningPlayerCastleComponent == nullptr)
			return;

		OwningPlayerCastleComponent.AddUltimateCharge(-UltimateSpendRate * DeltaTime);
	}

	void ReduceDuration(float DeltaTime)
	{
		if (OwningPlayerCastleComponent.UltimateCharge <= 0)
		{
			PlayAudioEventFromComponent(DeactivateAudioEvent);
			PlayAudioEvent(DestroyedAudioEvent);
			DestroyActor();
		}

		/*DurationCurrent -= DeltaTime;

		if (DurationCurrent <= 0)
			DestroyActor();*/
	}


	void DamageEnemy(ACastleEnemy CastleEnemy)
	{
		FCastleEnemyDamageEvent DamageEvent;
		DamageEvent.DamageDealt = DamagePerTick;
		DamageEvent.DamageDirection = (CastleEnemy.ActorLocation - ActorLocation).GetSafeNormal();
		DamageEvent.DamageSpeed = 750.f;
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
		DamageEvent.DamageSource = OwningPlayer;

		DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);

		AddTimeDilationEffectToActor(CastleEnemy, 2.f, 0.2f);
	}

	UFUNCTION()
	void OnDamageColliderBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		CheckAndAddCastleEnemy(OtherActor);
	}

	void CheckAndAddCastleEnemy(AActor OtherActor)
	{
		ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(OtherActor);

		if (CastleEnemy == nullptr)
			return;

		if (!bMoveAtDamageSpeed && ReducedSpeedAudioEvent != nullptr)
			PlayAudioEventFromComponent(ReducedSpeedAudioEvent);

		bMoveAtDamageSpeed = true;

		FCastleHitTimer OrbDamageTarget;
		OrbDamageTarget.CastleEnemy = CastleEnemy;
		OrbDamageTarget.Duration = TickInterval;

		OrbDamageTargets.Add(OrbDamageTarget);

		DamageEnemy(CastleEnemy);
	}

	void CheckAndAddBreakable(AActor OtherActor)
	{
		/*UBreakableComponent BreakableComponent = UBreakableComponent::Get(OtherActor);

		if (BreakableComponent == nullptr)
			return;

		bMoveAtDamageSpeed = true;

		FCastleOrbDamageTarget OrbDamageTarget;
		OrbDamageTarget.CastleEnemy = CastleEnemy;
		OrbDamageTarget.Duration = TickInterval;

		OrbDamageTargets.Add(OrbDamageTarget);

		DamageEnemy(CastleEnemy);*/
	}

	

	UFUNCTION()
    void OnDamageColliderEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(OtherActor);

		if (CastleEnemy == nullptr)
			return;

		for (int Index = 0, Count = OrbDamageTargets.Num(); Index < Count; ++Index)
		{
			if (CastleEnemy == OrbDamageTargets[Index].CastleEnemy)
			{
				OrbDamageTargets.RemoveAt(Index);
				break;
			}
		}

		if (OrbDamageTargets.Num() == 0)
		{
			bMoveAtDamageSpeed = false;
			if (IncreasedSpeedAudioEvent != nullptr)
				PlayAudioEventFromComponent(IncreasedSpeedAudioEvent);
		}
    }	

	void PlayAudioEvent(UAkAudioEvent AudioEvent)
	{
		if (AudioEvent != nullptr)
			HazeAkComp.HazePostEvent(AudioEvent);
	}

	void PlayAudioEventAtActor(UAkAudioEvent AudioEvent, AHazeActor Actor)
	{
		if (AudioEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(AudioEvent, Actor.GetActorTransform());
	}

	void PlayAudioEventFromComponent(UAkAudioEvent AudioEvent)
	{
		if (AudioEvent != nullptr)
			HazeAkComp.HazePostEvent(AudioEvent);
	}
}