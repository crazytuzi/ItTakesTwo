import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

class ACastleBruteIgnitedGround : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY()
	float Duration = 3.15f;

	UPROPERTY()
	float Radius = 400.f;

	UPROPERTY()
	int DPSMin = 15.f;

	UPROPERTY()
	int DPSMax = 20.f;

	UPROPERTY()
	float DamageInterval = 0.25f;

	AHazePlayerCharacter OwningPlayer;
	private float Lifetime = 0.f;
	private float DamageTick = 0.f;

	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;

	UPROPERTY()
	UAkAudioEvent EnemyHitAudioEvent;

	UPROPERTY()
	UAkAudioEvent DeactivatedAudioEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Lifetime = Duration;

		SpawnEffectRing(0.5f, PI * 0.5f);
		SpawnEffectRing(1.f, PI * 0.25f);

		if (ActivatedAudioEvent != nullptr)
			HazeAkComponent.HazePostEvent(ActivatedAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Lifetime -= DeltaTime;
		if (Lifetime <= 0.f)
		{
			if (DeactivatedAudioEvent != nullptr)
				HazeAkComponent.HazePostEvent(DeactivatedAudioEvent);
			DestroyActor();
		}

		DamageTick -= DeltaTime;
		if (DamageTick <= 0.f)
		{
			DamageTick = DamageInterval;
			for (auto Enemy : GetCastleEnemiesInSphere(ActorLocation, Radius))
			{
				if (!IsHittableByAttack(OwningPlayer, Enemy, Enemy.ActorLocation))
					continue;

				DamageEnemy(Enemy);
				BurnEnemy(Enemy);
				if (EnemyHitAudioEvent != nullptr)
					HazeAudio::PostEventAtLocation(EnemyHitAudioEvent, Enemy);
			}
		}
	}

	void DamageEnemy(ACastleEnemy CastleEnemy)
	{
		if (CastleEnemy == nullptr)
			return;

		FCastleEnemyDamageEvent DamageEvent;

		DamageEvent.DamageDealt = FMath::RandRange(DPSMin, DPSMax) * DamageInterval;
		DamageEvent.DamageSource = OwningPlayer;
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation + FVector(0, 0, 90);
		DamageEvent.DamageDirection = FVector::UpVector;
		DamageEvent.DamageType = ECastleEnemyDamageType::Burn;
		DamageEvent.DamageSpeed = 500.f;

		DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);
	}

	void BurnEnemy(ACastleEnemy CastleEnemy)
	{		
		if (CastleEnemy == nullptr)
			return;

		FCastleEnemyStatusEffect Status;
		Status.Type = ECastleEnemyStatusType::Burn;
		Status.Duration = 3.f;
		Status.Magnitude = 1.f;

		CastleEnemy.ApplyStatusEffect(Status);
	}

	void SpawnEffectRing(float Radius, float Step)
	{
		float Angle = 0.f;
		while (Angle < PI * 2.f)
		{
			SpawnEffectOrNot(FMath::Sin(Angle) * Radius, FMath::Cos(Angle) * Radius);
			Angle += Step;
		}
	}

	void SpawnEffectOrNot(float X, float Y)
	{
		FVector EffectLocation = ActorLocation;
		EffectLocation.X += Radius * X;
		EffectLocation.Y += Radius * Y;

		// Trace to see if there is a wall between us and the spot
		if (!IsHittableByAttack(this, nullptr, EffectLocation))
			return;

		// Trace to see if there is ground to spawn the effect at here
		FHitResult Hit;
		if (System::LineTraceSingle(
			EffectLocation,
			EffectLocation - FVector(0.f, 0.f, 50.f),
			ETraceTypeQuery::Visibility,
			false, TArray<AActor>(), EDrawDebugTrace::None,
			Hit, false))
		{
			if (Hit.bBlockingHit)
			{
				auto EffectComp = Niagara::SpawnSystemAttached(
					Effect, Root, NAME_None,
					FVector(), FRotator(),
					EAttachLocation::SnapToTarget,
					false, true);
				EffectComp.WorldLocation = EffectLocation;
			}
		}
	}
};