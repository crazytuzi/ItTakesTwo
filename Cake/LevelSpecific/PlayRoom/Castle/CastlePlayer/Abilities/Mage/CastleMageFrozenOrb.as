import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;
import Vino.Time.ActorTimeDilationStatics;
import Cake.Environment.BreakableComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Audio.CastleAudioStatics;
import Cake.Environment.BreakableStatics;

event void FOnOrbExploded();

UCLASS(Abstract)
class ACastleMageFrozenOrb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent OrbCollider;
	default OrbCollider.RelativeScale3D = FVector(0.1f);
	default OrbCollider.SphereRadius = 100.f;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent OrbEffect;
	default OrbEffect.SetActive(false);	

	AHazePlayerCharacter OwningPlayer;

	UPROPERTY()
	FOnOrbExploded OnOrbExploded;

	UPROPERTY()
	float MoveSpeed = 1800.f;
	UPROPERTY()
	float MoveAcceleration = 3000.f;
	UPROPERTY()
	int MinDamage = 35;
	UPROPERTY()
	int MaxDamage = 70;

	float ExplosionRadius = 600.f;

	UPROPERTY()
	float Duration = 6.f;
	float DurationCurrent = Duration;

	UPROPERTY()
	FHazeTimeLike StartOrbGrowthTimelike;
	default StartOrbGrowthTimelike.Duration = 0.5f;

	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;

	UPROPERTY()
	UAkAudioEvent ExplodeAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;

	TArray<AHazePlayerCharacter> Players;
	private bool bWasDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartOrbGrowthTimelike.BindUpdate(this, n"OnStartOrbGrowthTimelike");
		StartOrbGrowthTimelike.PlayFromStart();
		Players = Game::GetPlayers();		
		PlayAudioEventFromComponent(ActivatedAudioEvent);
		HazeAkComponent.SetStopWhenOwnerDestroyed(false);	
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
		if (bWasDestroyed)
			return;

		MoveOrb(DeltaTime);
		ReduceDuration(DeltaTime);
		SetSpeakerPanningFromMiddle();
	}

	void MoveOrb(float DeltaTime)
	{		
		FVector MoveDirection = ActorForwardVector.ConstrainToPlane(FVector::UpVector);
		MoveDirection.Normalize();

		FVector DeltaMove = MoveDirection * MoveSpeed * DeltaTime + MoveDirection * MoveAcceleration * DeltaTime * DeltaTime;
		MoveSpeed += MoveAcceleration * DeltaTime;

		FHitResult Hit;
		AddActorWorldOffset(DeltaMove, true, Hit, false);

		if (!bWasDestroyed && Hit.bBlockingHit)
			Explode();
	}

	void Explode()
	{
		OnOrbExploded.Broadcast();
		bWasDestroyed = true;

		PlayAudioEventFromComponent(ExplodeAudioEvent);	

		TArray<AHazeActor> HitActors = GetActorsInCone(ActorLocation, FRotator::ZeroRotator, ExplosionRadius, 360.f, false);
		TArray<ACastleEnemy> HitCastleEnemies = GetCastleEnemiesFromArray(HitActors);
		TArray<ABreakableActor> Breakables = GetBreakableActorsFromArray(HitActors);

		for (ACastleEnemy HitCastleEnemy : HitCastleEnemies)
		{
			if (!IsHittableByAttack(OwningPlayer, HitCastleEnemy, HitCastleEnemy.ActorLocation))
				continue;

			DamageEnemy(HitCastleEnemy);
			KnockbackEnemy(HitCastleEnemy);
			PlayAudioEventFromComponent(ExplodeAudioEvent);	
		}

		for (ABreakableActor Breakable : Breakables)
		{
			if (!IsHittableByAttack(OwningPlayer, Breakable, Breakable.ActorLocation))
				continue;

			FBreakableHitData BreakableData;
			BreakableData.HitLocation = Breakable.ActorLocation;
			BreakableData.DirectionalForce = (Breakable.ActorLocation - OwningPlayer.ActorLocation).GetSafeNormal() * 5.f;
			BreakableData.ScatterForce = 5.f;
			BreakableData.NumberOfHits = 2;

			Breakable.HitBreakableActor(BreakableData);
		}

		System::SetTimer(this, n"DelayedDeath", 2.f, false);
		OrbEffect.Deactivate();
	}

	UFUNCTION()
	void DelayedDeath()
	{
		DestroyActor();
	}

	void ReduceDuration(float DeltaTime)
	{
		DurationCurrent -= DeltaTime;

		if (DurationCurrent <= 0)
			DestroyActor();
	}

	void DamageEnemy(ACastleEnemy CastleEnemy)
	{
		FCastleEnemyDamageEvent DamageEvent;

		float DistanceToExplosion = CastleEnemy.ActorLocation.Dist2D(ActorLocation) - CastleEnemy.CapsuleComponent.ScaledCapsuleRadius;
		DamageEvent.DamageDealt = MinDamage + FMath::Clamp(1.f - (DistanceToExplosion / ExplosionRadius), 0.f, 1.f) * (MaxDamage - MinDamage);

		DamageEvent.DamageDirection = (CastleEnemy.ActorLocation - ActorLocation).GetSafeNormal();
		DamageEvent.DamageSpeed = 900.f;
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
		DamageEvent.DamageSource = OwningPlayer;

		DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);
	}

	void KnockbackEnemy(ACastleEnemy CastleEnemy)
	{		
		if (CastleEnemy == nullptr)
			return;

		FCastleEnemyKnockbackEvent KnockbackEvent;

		KnockbackEvent.Source = OwningPlayer;
		KnockbackEvent.Location = CastleEnemy.ActorLocation;
		KnockbackEvent.Direction = (CastleEnemy.ActorLocation - ActorLocation).GetSafeNormal();
		KnockbackEvent.HorizontalForce = 1.f;
		KnockbackEvent.VerticalForce = 1.f;
		KnockbackEvent.KnockBackCurveOverride;
		KnockbackEvent.KnockUpCurveOverride;

		CastleEnemy.KnockBack(KnockbackEvent);
	}

	void SetSpeakerPanningFromMiddle()
	{	
		if(bWasDestroyed)
			return;
			
		const float Pos = GetObjectScreenPos(this);
		HazeAudio::SetPlayerPanning(HazeAkComponent, nullptr, Pos);
	}

	void PlayAudioEventFromComponent(UAkAudioEvent AudioEvent)
	{
		if (AudioEvent != nullptr)
			HazeAkComponent.HazePostEvent(AudioEvent);
	}
}