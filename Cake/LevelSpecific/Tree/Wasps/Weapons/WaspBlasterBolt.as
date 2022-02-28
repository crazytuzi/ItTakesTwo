import Vino.PlayerHealth.PlayerHealthStatics;

class AWaspBlasterBolt : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent MeshComp;
    default MeshComp.StaticMesh = Asset("/Game/Environment/Props/Fantasy/PlayRoom/Mechanical/BowlingBall_01.BowlingBall_01");
    default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
    default MeshComp.RelativeScale3D = FVector(0.05f, 0.05f, 0.05f);

    UPROPERTY(Category = "Effects")
    UNiagaraSystem MuzzleFlashEffect = Asset("/Game/Effects/Gameplay/Wasps/WaspBlasterBoltShoot.WaspBlasterBoltShoot");
    
    default SetActorHiddenInGame(true);
    default PrimaryActorTick.bStartWithTickEnabled = false;

    bool bIsBeingUsed = false;
    FVector CurVelocity = FVector::ZeroVector;
    AHazeActor Shooter = nullptr;
    float UnspawnTime = 0.f;

    bool IsAvailable()
    {
        return !bIsBeingUsed;
    }

    void Shoot(AHazeActor InShooter, const FVector& InLocation, const FVector& InVelocity, float LifeTime = 5.f)
    {
        if (bIsBeingUsed)
            return;

        bIsBeingUsed = true;
        Shooter = InShooter;
        SetActorLocation(InLocation);
        SetActorRotation(CurVelocity.Rotation());
        CurVelocity = InVelocity;        
        UnspawnTime = Time::GetGameTimeSeconds() + LifeTime;
        SetActorHiddenInGame(false);
        SetActorTickEnabled(true);
        Niagara::SpawnSystemAtLocation(MuzzleFlashEffect, InLocation, InVelocity.Rotation());
    }

    void HitTarget(AActor Target)
    {
        if (!bIsBeingUsed)
            return;

        Unspawn();

        AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
        if (PlayerTarget != nullptr)
            DamagePlayerHealth(PlayerTarget, 0.25f);
    }

    void Unspawn()
    {
        if (!bIsBeingUsed)
            return;

        SetActorHiddenInGame(true);
        SetActorTickEnabled(false);
        bIsBeingUsed = false;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
        if (!bIsBeingUsed)
            return;

        FVector CurLoc = GetActorLocation();
        FVector NextLoc = CurLoc + CurVelocity * DeltaSeconds;
        TArray<AActor> Ignores; 
        Ignores.Add(Shooter);
        FHitResult HitRes;
        if (System::LineTraceSingle(CurLoc, NextLoc, ETraceTypeQuery::WeaponTrace, false, Ignores, EDrawDebugTrace::None, HitRes, true))
            HitTarget(HitRes.Actor);
        else if (Time::GetGameTimeSeconds() > UnspawnTime)
            Unspawn();
        else
            SetActorLocation(NextLoc);
    }
}

