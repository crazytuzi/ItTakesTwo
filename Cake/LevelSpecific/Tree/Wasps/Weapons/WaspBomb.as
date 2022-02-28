import Vino.Checkpoints.Statics.LivesStatics;

class AWaspBomb : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent Collision;
    default Collision.SetSphereRadius(40.f);
    default Collision.CollisionProfileName = n"WeaponDefault";
    default Collision.CollisionEnabled = ECollisionEnabled::NoCollision; 

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent MeshComp;
    default MeshComp.StaticMesh = Asset("/Game/Environment/Props/Fantasy/PlayRoom/Mechanical/BowlingBall_01.BowlingBall_01");
    default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
    default MeshComp.RelativeScale3D = FVector(0.07f, 0.07f, 0.07f);

    UPROPERTY(Category = "Effects")
    UNiagaraSystem ExplosionEffect = Asset("/Game/Effects/Gameplay/Sap/Sap_Detonation_System.Sap_Detonation_System");

    default SetActorHiddenInGame(true);
    default PrimaryActorTick.bStartWithTickEnabled = false;

    bool bIsBeingUsed = false;
    FVector CurVelocity = FVector::ZeroVector;
    AActor Wielder = nullptr;
    float ExplodeTime = 0.f;
    float PrimeTime = 0.f;

    bool IsAvailable()
    {
        return !bIsBeingUsed;
    }

    void Wield(USceneComponent AttachTo)
    {
        if (bIsBeingUsed || (AttachTo == nullptr))
            return;

        Wielder = AttachTo.GetOwner();
        bIsBeingUsed = true;
        AttachToComponent(AttachTo);
        SetActorHiddenInGame(false);
        SetActorTickEnabled(false);
    }

    void Drop(const FVector& DropVelocity)
    {
        if (!bIsBeingUsed)
            return;

        DetachRootComponentFromParent();
        CurVelocity = DropVelocity;
        SetActorTickEnabled(true);
        PrimeTime = Time::GetGameTimeSeconds() + 0.3f;
    }

    void Prime()
    {
        if (!bIsBeingUsed)
            return;

        PrimeTime = 0.f;
        Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
        Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
        ExplodeTime = Time::GetGameTimeSeconds() + 2.f;
    }

    UFUNCTION()
    void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
        if (!Hit.bBlockingHit)
            return;
        if (OtherComponent.IsA(UHazeTriggerComponent::StaticClass()))
            return;
        if (OtherActor.IsA(AVolume::StaticClass()))
            return;
        if (OtherActor == Wielder)
            return;

        Explode();        
    }

    void Explode()
    {
        if (!bIsBeingUsed)
            return;

        Unwield();

        float BlastRadiusSqr = FMath::Square(400.f);
        FVector GroundZero = GetActorLocation();
        Niagara::SpawnSystemAtLocation(ExplosionEffect, GroundZero);
        TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
        for (AHazePlayerCharacter Player : Players)
        {
            if (GroundZero.DistSquared(Player.GetActorLocation()) < BlastRadiusSqr)
            {
                Player.SetCapabilityAttributeObject(n"WaspExplosion", this);
            }
        }
    }

    void Unwield()
    {
        if (!bIsBeingUsed)
            return;

        DetachRootComponentFromParent();
        SetActorHiddenInGame(true);
        SetActorTickEnabled(false);
        Collision.OnComponentBeginOverlap.Unbind(this, n"OnOverlap");
        Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        bIsBeingUsed = false;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
        if (!bIsBeingUsed)
            return;

        float CurTime = Time::GetGameTimeSeconds();
        if (CurTime > PrimeTime)
        {
            if (PrimeTime != 0.f)
                Prime();

            if (CurTime > ExplodeTime)
            {
                Explode();
                return;
            }
        }

        float Acceleration = 2000.f;
        FVector AccleratedVelocity = -FVector::UpVector * Acceleration;
        FVector Dampening = CurVelocity * 0.05f;
        CurVelocity += (AccleratedVelocity - Dampening) * DeltaSeconds;
        FVector Destination = GetActorLocation() + CurVelocity * DeltaSeconds;
        FHitResult Impact;
        SetActorLocation(Destination, true, Impact, false);

        if (Impact.bBlockingHit && (CurTime > PrimeTime))
            Explode();
    }
}