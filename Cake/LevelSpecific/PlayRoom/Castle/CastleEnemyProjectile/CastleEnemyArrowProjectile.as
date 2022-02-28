import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyProjectile;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Audio.CastleAudioStatics;

import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

class ACastleEnemyArrowProjectile : ACastleEnemyProjectile
{
    // Speed that the projectile moves at
    UPROPERTY()
    float Speed = 3000.f;

    // Acceleration that the projectile gains speed at
    UPROPERTY()
    float Acceleration = 4000.f;

    // If the projectile reaches this range without hitting a wall, it will expire
    UPROPERTY()
    float MaxRange = -1.f;

	UPROPERTY()
	UForceFeedbackEffect HitForceFeedback;

    // Additional root rotation
    UPROPERTY()
    FRotator RotationOffset;

    // Damage effect when the player is hit
    UPROPERTY()
    TSubclassOf<UCastleDamageEffect> DamageEffect;

	// How long the projectile will not hit a player for after hitting that player
	UPROPERTY()
	float HitDetectionCooldown = 1.f;

	UPROPERTY()
	bool bDestroyOnHitWall = true;

    FVector StartLocation;
    bool bFinished = false;
	bool bFired = false;

	TPerPlayer<float> PlayerCooldown;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlayerHitAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WallHitAudioEvent;

	UPROPERTY(NotVisible)
	UDopplerEffect ProjectileDoppler;

    void ProjectileTargeted() override
    {
        ACastleEnemyProjectile::ProjectileTargeted();
        SetActorRotation(Math::MakeRotFromX(FireDirection) + RotationOffset);
	}

    void ProjectileFired() override
    {
        ACastleEnemyProjectile::ProjectileFired();
        StartLocation = ActorLocation;
		bFired = true;

		for(float& Cooldown : PlayerCooldown)
			Cooldown = 0.f;

        SetActorRotation(Math::MakeRotFromX(FireDirection) + RotationOffset);
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileDoppler = Cast<UDopplerEffect>(ProjectileHazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (!bFired || bFinished)
			return;

		for (auto Player : Game::GetPlayers())
		{
			PlayerCooldown[Player] -= DeltaTime;

			if (Trace::ComponentOverlapComponent(Player.CapsuleComponent, CollisionBox, CollisionBox.WorldLocation, CollisionBox.ComponentQuat))
			{
				if (PlayerCooldown[Player] <= 0)
					HitPlayer(Player);
			}
		}

        FVector PrevPosition = ActorLocation;

		FVector MoveDirection = FireDirection.GetSafeNormal();
        FVector NewPosition = PrevPosition + MoveDirection * (Speed * DeltaTime) + MoveDirection * (Acceleration * DeltaTime * DeltaTime);
		Speed += Acceleration * DeltaTime;

        FHitResult Hit;
        SetActorLocation(NewPosition, true, Hit, false);

        if (Hit.Actor != nullptr)
        {
            HitWall();
        }
        else
        {
            if (MaxRange > 0.f && NewPosition.Distance(StartLocation) > MaxRange)
                Expire();
        }

		const float ScreenPos = GetObjectScreenPos(this);
		HazeAudio::SetPlayerPanning(ProjectileHazeAkComp, nullptr, ScreenPos);
    }

	void HitPlayer(AHazePlayerCharacter Player)
	{
		if (!Player.CanPlayerBeDamaged())
			return;

		FCastlePlayerDamageEvent Evt;
		Evt.DamageSource = this;
		Evt.DamageDealt = ProjectileDamageRoll;
		Evt.DamageLocation = Player.ActorCenterLocation;
		Evt.DamageDirection = FireDirection.GetSafeNormal();
		Evt.DamageEffect = DamageEffect;

		Player.DamageCastlePlayer(Evt);
		if (HitForceFeedback != nullptr)
			Player.PlayForceFeedback(HitForceFeedback, false, false, n"CastleHit");
		PlayerCooldown[Player] = HitDetectionCooldown;
		PlayPlayerHitAudioEvent(Player);

		float KnockForce = 400.f;
		FVector KnockImpulse = FireDirection.GetSafeNormal() * KnockForce + FVector(0.f, 0.f, 1000.f);
		Player.KnockdownActor(KnockImpulse);
		Player.AddPlayerInvulnerabilityDuration(1.f);
	}

    void Expire()
    {
        if (bFinished)
            return;
        bFinished = true;

        // The projectile should be destroyed when it expires
        DestroyActor();
    }

    void HitWall()
    {
        if (bFinished)
            return;
        bFinished = true;

        BP_HitWall();

		ProjectileHazeAkComp.HazePostEvent(WallHitAudioEvent);

        // The projectile should be destroyed when it hits a wall
		if (bDestroyOnHitWall)
			DestroyActor();
    }

    UFUNCTION(BlueprintEvent, Meta=(DisplayName = "Projectile Hit Wall"))
    void BP_HitWall() {}

	void PlayPlayerHitAudioEvent(AHazeActor Actor)
	{
		if (PlayerHitAudioEvent != nullptr && Actor != nullptr)
		{
			ProjectileHazeAkComp.HazePostEvent(PlayerHitAudioEvent);
		}
	}
};