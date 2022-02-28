import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyProjectile;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

import Vino.Trajectory.TrajectoryStatics;

class ACastleEnemyMortarProjectile : ACastleEnemyProjectile
{
    // Height that the projectile reaches in its arc
    UPROPERTY()
    float Height = 500.f;

    // Gravity constant for the projectile
    UPROPERTY()
    float Gravity = 980.f;

    // Random target position offset
    UPROPERTY()
    float RandomTargetOffset = 100.f;

    // Radius from the explosion that players get damaged in
    UPROPERTY()
    float ExplosionRadius = 200.f;

    // Explosion niagara effect
    UPROPERTY()
    UNiagaraSystem ExplosionEffect;

    // Damage effect when the player is hit
    UPROPERTY()
    TSubclassOf<UCastleDamageEffect> DamageEffect;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ExplosionEvent;

    FVector ProjectileVelocity;
    float GroundHeight;
    bool bExploded = false;
	bool bFired = false;

    void ProjectileFired() override
    {
        ACastleEnemyProjectile::ProjectileFired();

        FVector Offset = FMath::VRand();
        Offset.Z = 0.f;
        Offset *= RandomTargetOffset;
        TargetLocation += Offset;

        ProjectileVelocity = CalculateVelocityForPathWithHeight(ActorLocation, TargetLocation, Gravity, Height);
        GroundHeight = Target.ActorLocation.Z;
		bFired = true;
    }

    UFUNCTION(BlueprintPure)
    FVector GetGroundPositionBelowProjectile()
    {
        FVector Location = ActorLocation;
        Location.Z = GroundHeight;
        return Location;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (!bFired)
			return;

        // Update the position of the projectile
        FVector PrevVelocity = ProjectileVelocity;
        ProjectileVelocity -= FVector::UpVector * Gravity * DeltaTime;

        FVector DeltaMove = PrevVelocity * DeltaTime;
        DeltaMove += (ProjectileVelocity - PrevVelocity) * DeltaTime * 0.5f;

        FVector NewLocation = ActorLocation + DeltaMove;
        SetActorLocation(NewLocation);

        // Explode when we hit the ground
        if (NewLocation.Z <= GroundHeight)
            Explode();
    }

    void Explode()
    {
        if (bExploded)
            return;

        bExploded = true;
        FVector ExplosionLocation = ActorLocation;

        //System::DrawDebugSphere(ExplosionLocation, ExplosionRadius, Duration = 1.f);

        // Damage the players in the radius
        for (AHazePlayerCharacter Player : Game::GetPlayers())
        {
            float Distance = Player.ActorLocation.Distance(ExplosionLocation);
            if (Distance > ExplosionRadius)
                continue;
			if (Player.bHidden)
				continue;

            //System::DrawDebugPoint(Player.ActorLocation, 50.f, PointColor = FLinearColor::Red, Duration = 2.f);

            FVector ToPlayer = Player.ActorLocation - ExplosionLocation;

            FCastlePlayerDamageEvent Evt;
            Evt.DamageSource = this;
            Evt.DamageDealt = ProjectileDamageRoll;
            Evt.DamageLocation = Player.ActorCenterLocation;
            Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
            Evt.DamageEffect = DamageEffect;

            Player.DamageCastlePlayer(Evt);
        }

        // Show the explosion effect
        if (ExplosionEffect != nullptr)
            Niagara::SpawnSystemAtLocation(ExplosionEffect, ActorLocation);

        BP_Explode();
		ProjectileHazeAkComp.HazePostEvent(ExplosionEvent);

        // The projectile should be destroyed once exploded
        DestroyActor();
    }

    UFUNCTION(BlueprintEvent, Meta=(DisplayName = "Projectile Exploded"))
    void BP_Explode() {}
};