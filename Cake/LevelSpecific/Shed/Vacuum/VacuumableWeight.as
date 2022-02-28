import Cake.LevelSpecific.Shed.Vacuum.VacuumableComponent;
import Cake.LevelSpecific.Shed.Vacuum.VacuumShootingComponent;
import Vino.Projectile.ProjectileMovement;

event void FOnWeightVacuumed(AVacuumableWeight Weight);

class AVacuumableWeight : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent VisibleMesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent DestroyEffect;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent LandEffect;

    UPROPERTY(DefaultComponent)
    UVacuumableComponent VacuumableComponent;

    bool bLaunchedFromSpawner = false;
    bool bLanded = false;
    bool bShotFromHose = false;
    bool bTargetHit = false;

    UPROPERTY()
    AActor LandingTarget;

    USceneComponent EntryNozzle;

	UHazeSplineComponent SplineToFollow;

	UPROPERTY()
	FHazeTimeLike SpawnTimeLike;
	default SpawnTimeLike.Duration = 1.f;
	float SpawnRotationRate = 1000.f;

    UPROPERTY()
    FHazeTimeLike VacuumedTimeLike;
    default VacuumedTimeLike.Duration = 0.2f;

	UPROPERTY()
	FHazeTimeLike EnterBowlTimeLike;
	default EnterBowlTimeLike.Duration = 0.1f;
	FVector EnterBowlStartLoc;
	USceneComponent EnterBowlTargetPoint;

    FProjectileMovementData ProjectileMovementData;
    default ProjectileMovementData.Gravity = 980.f;

    float ShotSpeedMultiplier = 2.f;

    FOnWeightVacuumed OnWeightVacuumed;
	FOnWeightVacuumed OnWeightDestroyed;

	FVector VacuumedStartLocation;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ShootObjectEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LandObjectEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DestroyObjectEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitVacuumObjectEvent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Ignore);

        VacuumableComponent.OnStartVacuuming.AddUFunction(this, n"StartVacuuming");
        VacuumableComponent.OnEnterVacuum.AddUFunction(this, n"EnterVacuum");
        VacuumableComponent.OnExitVacuum.AddUFunction(this, n"ExitVacuum");

		SpawnTimeLike.BindUpdate(this, n"UpdateSpawn");
		SpawnTimeLike.BindFinished(this, n"FinishSpawn");

        VacuumedTimeLike.BindUpdate(this, n"UpdateVacuumed");

		EnterBowlTimeLike.BindUpdate(this, n"UpdateEnterBowl");
		EnterBowlTimeLike.BindFinished(this, n"FinishEnterBowl");
    }

    UFUNCTION()
    void LaunchFromSpawner(UHazeSplineComponent Spline)
    {
		bLanded = false;
		bShotFromHose = false;
		bTargetHit = false;
		SplineToFollow = Spline;
        bLaunchedFromSpawner = true;
		
		UHazeAkComponent::HazePostEventFireForget(ShootObjectEvent, GetActorTransform());

		SpawnRotationRate = FMath::RandRange(500.f, 800.f);
		bool bRand = FMath::RandBool();
		if (bRand)
			SpawnRotationRate *= -1;
		SpawnTimeLike.PlayFromStart();

		VisibleMesh.SetHiddenInGame(false);
    }

	UFUNCTION()
	void UpdateSpawn(float CurValue)
	{
		FVector CurLoc = SplineToFollow.GetLocationAtTime(CurValue, ESplineCoordinateSpace::World);
		SetActorLocation(CurLoc);

		AddActorWorldRotation(FRotator(0.f, SpawnRotationRate * ActorDeltaSeconds, 0.f));
		float CurRoll = FMath::Lerp(0.f, 720.f, CurValue);
		FRotator Rot = FRotator(0.f, ActorRotation.Yaw, CurRoll);
		SetActorRotation(Rot);
	}

	UFUNCTION()
	void FinishSpawn()
	{
		LandEffect.Activate(true);
		
		UHazeAkComponent::HazePostEventFireForget(LandObjectEvent, GetActorTransform());
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        if (!bTargetHit)
        {
            if (bShotFromHose)
            {
                FProjectileUpdateData ProjectileUpdateData = CalculateProjectileMovement(ProjectileMovementData, Delta * ShotSpeedMultiplier);
                ProjectileMovementData = ProjectileUpdateData.UpdatedMovementData;

                FHitResult HitResult;
                AddActorWorldOffset(ProjectileUpdateData.DeltaMovement, true, HitResult, false);
				AddActorWorldRotation(FRotator(450.f * Delta, 1000.f * Delta, 800.f * Delta));

                if (HitResult.bBlockingHit)
                {
                    bTargetHit = true;
                    DestroyWeight(true);
                }
            }
        }
    }

    UFUNCTION()
    void UpdateVacuumed(float Value)
    {
        FVector CurrentLocation = FMath::Lerp(VacuumedStartLocation, EntryNozzle.WorldLocation, Value);
        SetActorLocation(CurrentLocation);
		AddActorWorldRotation(FRotator(450.f * ActorDeltaSeconds, 1000.f * ActorDeltaSeconds, 800.f * ActorDeltaSeconds));
    }

    UFUNCTION()
    void WeightLanded()
    {
        bLanded = true;
    }

    UFUNCTION()
    void StartVacuuming(USceneComponent NozzleComponent)
    {
		EntryNozzle = NozzleComponent;
		SpawnTimeLike.Stop();
		VacuumedStartLocation = ActorLocation;
		VacuumedTimeLike.PlayFromStart();
    }

    UFUNCTION()
    void EnterVacuum(USceneComponent NozzleComp)
    {
        OnWeightVacuumed.Broadcast(this);
		VacuumableComponent.bCanEnterVacuum = false;
		VacuumableComponent.bAffectedByVacuum = false;
    }

    UFUNCTION()
    void ExitVacuum()
    {
        UVacuumShootingComponent ShootingComponent = Cast<UVacuumShootingComponent>(EntryNozzle.Owner.GetComponentByClass(UVacuumShootingComponent::StaticClass()));

        ProjectileMovementData.Velocity = ShootingComponent.DebrisLaunchForce;
        bShotFromHose = true;
    }

    void LandInWeightBowl(USceneComponent TargetPoint)
    {
		bTargetHit = true;
		bShotFromHose = false;
		EnterBowlTargetPoint = TargetPoint;
		EnterBowlStartLoc = ActorLocation;
		EnterBowlTimeLike.PlayFromStart();
		
		UHazeAkComponent::HazePostEventFireForget(HitVacuumObjectEvent, GetActorTransform());
    }

	UFUNCTION(NotBlueprintCallable)
	void UpdateEnterBowl(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(EnterBowlStartLoc, EnterBowlTargetPoint.WorldLocation, CurValue);
		SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishEnterBowl()
	{
		DestroyWeight(false);
	}

	void DestroyWeight(bool bSpawnEffect)
	{
		if (bSpawnEffect)
			DestroyEffect.Activate(true);
		
		UHazeAkComponent::HazePostEventFireForget(DestroyObjectEvent, GetActorTransform());
		VisibleMesh.SetHiddenInGame(true);
		OnWeightDestroyed.Broadcast(this);
		bTargetHit = true;
		bShotFromHose = false;
	}
}