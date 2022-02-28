import Vino.Checkpoints.Statics.LivesStatics;
import Vino.Combustible.CombustibleComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;

class AWaspShell : AHazeActor
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
    
    UPROPERTY(Category = "Effects")
    UNiagaraSystem MuzzleFlashEffect = Asset("/Game/Effects/Gameplay/Wasps/WaspBlasterBoltShoot.WaspBlasterBoltShoot");

    UPROPERTY(Category = "Effects")
    UNiagaraSystem ExplosionEffect = Asset("/Game/Effects/Gameplay/Sap/Sap_Detonation_System.Sap_Detonation_System");

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LarvaMortarExplosionEvent;

	UPROPERTY(DefaultComponent)
	UDecalComponent HitLocationDecal;
	default HitLocationDecal.DecalMaterial = Asset("/Game/Environment/Decals/Decal_RedCircle.Decal_RedCircle");
	default HitLocationDecal.bVisible = false;
	default HitLocationDecal.bDestroyOwnerAfterFade = false; 
	default HitLocationDecal.SetRelativeRotation(FRotator(90.f, 0.f, 0.f));

	UPROPERTY(DefaultComponent)
	UWaspRespawnerComponent RespawnComp;

    UPROPERTY()
    float Gravity = 2000.f;
	float DefaultGravity = Gravity;

    default SetActorHiddenInGame(true);
    default PrimaryActorTick.bStartWithTickEnabled = false;

    FVector CurVelocity = FVector::ZeroVector;
    AActor Shooter = nullptr;
    float ExplodeTime = 0.f;
    float PrimeTime = 0.f;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// In case gravity is tweaked by shooter
		DefaultGravity = Gravity;
	}

    void Shoot(AHazeActor InShooter, const FVector& ShootLocation, const FVector& InVelocity, const FVector& TargetLocation, float LifeTime = 5.f)
    {
        Shooter = InShooter;
        SetActorLocation(ShootLocation);
        SetActorRotation(CurVelocity.Rotation());
        SetActorHiddenInGame(false);
        CurVelocity = InVelocity;
        SetActorTickEnabled(true);
        PrimeTime = Time::GetGameTimeSeconds() + 0.3f;
        Niagara::SpawnSystemAtLocation(MuzzleFlashEffect, ShootLocation, InVelocity.Rotation());
        ExplodeTime = Time::GetGameTimeSeconds() + LifeTime;
		
		HitLocationDecal.DetachFromParent();
		HitLocationDecal.SetWorldLocation(TargetLocation + FVector(0.f, 0.f , 100.f));
		HitLocationDecal.SetVisibility(true);
    }

    void Prime()
    {
        PrimeTime = 0.f;
        Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
        Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
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
        if (OtherActor == Shooter)
            return;

        Explode();        
    }

    void Explode()
    {
        Unspawn();
		UHazeAkComponent::HazePostEventFireForget(LarvaMortarExplosionEvent, GetActorTransform());
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

    void Unspawn()
    {
        SetActorHiddenInGame(true);
        SetActorTickEnabled(false);
        Collision.OnComponentBeginOverlap.Unbind(this, n"OnOverlap");
        Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		HitLocationDecal.SetVisibility(false);
		Gravity = DefaultGravity;
		RespawnComp.UnSpawn(this);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
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

        FVector AccleratedVelocity = -FVector::UpVector * Gravity;
        FVector Dampening = CurVelocity * 0.00f;
        CurVelocity += (AccleratedVelocity - Dampening) * DeltaSeconds;
        FVector Destination = GetActorLocation() + CurVelocity * DeltaSeconds;
        FHitResult Impact;
        SetActorLocation(Destination, true, Impact, false);

        if (Impact.bBlockingHit && (CurTime > PrimeTime))
            Explode();
    }
}