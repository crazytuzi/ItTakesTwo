import Vino.Projectile.ProjectileMovement;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Vino.Checkpoints.Statics.DeathStatics;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Shed.Vacuum.VacuumShootingComponent;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBossBackPlatform;

event void FOnBombLanded();
event void FOnBombSucked(AActor Target);
event void FOnBombDestroyed(AVacuumBossBomb Bomb);

UCLASS(Abstract)
class AVacuumBossBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BombRoot;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
    UStaticMeshComponent BombMesh;
    default BombMesh.LightmapType = ELightmapType::ForceVolumetric;
    default BombMesh.CastShadow = false;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UCapsuleComponent HurtTrigger;
    default HurtTrigger.CapsuleRadius = 70.f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UDecalComponent DangerZoneDecal;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
	UNiagaraComponent FireEffect;
	default FireEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
	UNiagaraComponent BurnEffect;
	default BurnEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
	UNiagaraComponent LandingEffect;
	default LandingEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UVacuumableComponent VacuumableComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LaunchEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExploEvent;

	UPROPERTY()
    bool bBeingLaunched = false;

    UPROPERTY()
    bool bGoingThroughHose = false;

    UPROPERTY()
    AActor CurrentTarget;

    UPROPERTY()
    UNiagaraSystem ExplosionEffect;

    UPROPERTY()
    FOnBombLanded OnBombLanded;

    UPROPERTY()
    FOnBombSucked OnBombSucked;

    UPROPERTY()
    FOnBombDestroyed OnBombDestroyed;

    FProjectileMovementData ProjectileMovementData;
	default ProjectileMovementData.Gravity = 980.f;

    float LaunchDelay = 0.5f;

    bool bLanded = false;
	bool bDestroyed = false;

    UPROPERTY()
    bool bShot = false;

	UPROPERTY(NotEditable)
    FVector TargetLocation;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> PlayerDamageEffect;

	USceneComponent NozzleComp;

	FVector SuckStartLocation;
	FRotator SuckStartRotation;

	FHazeTimeLike StartVacuumingTimeLike;
	default StartVacuumingTimeLike.Duration = 0.25f;

	TArray<AActor> ActorsToIgnore;
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        HurtTrigger.OnComponentBeginOverlap.AddUFunction(this, n"DamagePlayer");

		VacuumableComp.OnStartVacuuming.AddUFunction(this, n"StartVacuuming");
		VacuumableComp.OnEnterVacuum.AddUFunction(this, n"EnterVacuum");
		VacuumableComp.OnExitVacuum.AddUFunction(this, n"ExitVacuum");
		
		StartVacuumingTimeLike.BindUpdate(this, n"UpdateStartVacuuming");

		ActorsToIgnore.Add(Game::GetCody());
        ActorsToIgnore.Add(Game::GetMay());

		SetActorTickEnabled(false);
		DangerZoneDecal.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		DangerZoneDecal.SetWorldRotation(FRotator(-90.f, 0.f, 0.f));
    }

	UFUNCTION()
	void SetToIgnoreOtherBombs()
	{
		TArray<AActor> BackPlatforms;
		Gameplay::GetAllActorsOfClass(AVacuumBossBackPlatform::StaticClass(), BackPlatforms);
		for (AActor CurPlatform : BackPlatforms)
		{
			AVacuumBossBackPlatform Platform = Cast<AVacuumBossBackPlatform>(CurPlatform);
			if (Platform != nullptr)
				ActorsToIgnore.Add(Platform);
		}

		TArray<AActor> Bombs;
		Gameplay::GetAllActorsOfClass(AVacuumBossBomb::StaticClass(), Bombs);
		for (AActor CurBomb : Bombs)
		{
			AVacuumBossBomb Bomb = Cast<AVacuumBossBomb>(CurBomb);
			if (Bomb != nullptr)
				ActorsToIgnore.Add(Bomb);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StartVacuuming(USceneComponent Nozzle)
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		ActorsToIgnore.AddUnique(Nozzle.Owner);

		NozzleComp = Nozzle;
		VacuumableComp.bAffectedByVacuum = false;
		BombMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Ignore);
		SuckStartLocation = ActorLocation;
		SuckStartRotation = ActorRotation;
		bGoingThroughHose = true;
		StartVacuumingTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterVacuum(USceneComponent Nozzle)
	{		
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		ActorsToIgnore.AddUnique(Nozzle.Owner);

		NozzleComp = Nozzle;
		VacuumableComp.bAffectedByVacuum = false;
		BombMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Ignore);
		bGoingThroughHose = true;

		StartVacuumingTimeLike.Stop();
		OnBombSucked.Broadcast(CurrentTarget);

		FireEffect.Deactivate();
		BurnEffect.Deactivate();
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitVacuum()
	{
		UVacuumShootingComponent VacuumShootingComp =  UVacuumShootingComponent::Get(NozzleComp.Owner);
		ProjectileMovementData.Velocity = VacuumShootingComp.DebrisLaunchForce;
		bShot = true;
		bGoingThroughHose = false;

		FireEffect.Activate(false);
		BurnEffect.Activate(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateStartVacuuming(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(SuckStartLocation, NozzleComp.WorldLocation, CurValue);
		SetActorLocation(CurLoc);

		FVector Dir = -NozzleComp.ForwardVector;
		FRotator TargetRot = Math::MakeRotFromZ(Dir);
		FRotator CurRot = FMath::LerpShortestPath(SuckStartRotation, TargetRot, CurValue);
		SetActorRotation(CurRot);
	}

    UFUNCTION(NotBlueprintCallable)
	void DamagePlayer(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
        if (!bGoingThroughHose && !bShot)
        {
            AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

            if (Player != nullptr && !bGoingThroughHose)
            {
				DamagePlayerHealth(Player, 0.5f, PlayerDamageEffect);
                NetDestroyBomb();
            }

            AVacuumHoseActor Hose = Cast<AVacuumHoseActor>(OtherActor);

            if (Hose != nullptr && bLanded && OtherComponent != Hose.FrontCapsule)
            {
                NetDestroyBomb();
            }
        }
    }

    UFUNCTION(NetFunction)
    void NetLaunchBomb(FVector StartLoc, FVector TargetLoc, float GroundLoc, FRotator StartRot)
    {
		SetActorTickEnabled(true);
        TargetLocation = FVector(TargetLoc.X, TargetLoc.Y, GroundLoc);

        FVector Velocity = CalculateVelocityForPathWithHeight(StartLoc, TargetLocation, 980.f, 500.f);

		BombMesh.SetHiddenInGame(false);
		DangerZoneDecal.SetWorldLocation(TargetLocation);
		DangerZoneDecal.SetHiddenInGame(false);

		ProjectileMovementData.Velocity = Velocity;
		TeleportActor(StartLoc, StartRot);
		BombRoot.SetRelativeRotation(FRotator::ZeroRotator);
		bDestroyed = false;
		SetActorHiddenInGame(false);
		SetActorEnableCollision(true);
        bBeingLaunched = true;
		VacuumableComp.bAffectedByVacuum = true;
		VacuumableComp.bCanEnterVacuum = true;

		FireEffect.Activate(true);
		BurnEffect.Activate(true);

		HazeAkComp.HazePostEvent(LaunchEvent);
		

		BP_LaunchBomb();
    }

	UFUNCTION(BlueprintEvent)
	void BP_LaunchBomb() {}

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
		if (bShot)
		{
			FProjectileUpdateData UpdateData = CalculateProjectileMovement(ProjectileMovementData, Delta * 2.f);
            ProjectileMovementData = UpdateData.UpdatedMovementData;

            AddActorWorldOffset(UpdateData.DeltaMovement);

			FVector Dir = UpdateData.DeltaMovement.GetSafeNormal();
			FRotator Rot = Math::MakeRotFromZ(Dir);
			SetActorRotation(Rot);

			FVector TraceStartLoc = HurtTrigger.WorldLocation + (HurtTrigger.UpVector * 25.f);
			FHitResult HitResult;
			System::CapsuleTraceSingle(TraceStartLoc, TraceStartLoc + FVector(0.f, 0.f, 0.1f), 50.f, 110.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

			if (HitResult.bBlockingHit)
			{
				BP_ShotImpact(HitResult.Actor);
				bShot = false;
				NetDestroyBomb();
			}
		}
    }

	UFUNCTION(BlueprintEvent)
	void BP_ShotImpact(AActor Actor) {}

	UFUNCTION()
    void BombLanded()
    {
        bLanded = true;
        bBeingLaunched = false;
		LandingEffect.Activate(true);
		DangerZoneDecal.SetHiddenInGame(true);

		TArray<AActor> ActorsToIgnoreWhenLanding;
		ActorsToIgnoreWhenLanding.Add(Game::GetCody());
		ActorsToIgnoreWhenLanding.Add(Game::GetMay());
		FHitResult Hit;
		System::LineTraceSingle(ActorLocation + FVector(0.f, 0.f, 50.f), ActorLocation - FVector(0.f, 0.f, 100.f), ETraceTypeQuery::Visibility, false, ActorsToIgnoreWhenLanding, EDrawDebugTrace::None, Hit, true);
		if (Hit.bBlockingHit)
		{
			AttachToComponent(Hit.Component, NAME_None, EAttachmentRule::KeepWorld);
			UHazeAkComponent::HazePostEventFireForget(ImpactEvent, FTransform(Hit.Location));
		}
		else
			NetDestroyBomb();

		TArray<AActor> Actors;
		HurtTrigger.GetOverlappingActors(Actors, AVacuumBossBomb::StaticClass());
		for (AActor CurActor : Actors)
		{
			AVacuumBossBomb Bomb = Cast<AVacuumBossBomb>(CurActor);
			if (Bomb != nullptr)
			{
				NetDestroyBomb();
				return;
			}
		}
    }

    UFUNCTION(NetFunction)
    void NetDestroyBomb()
    {
		if (bDestroyed)
			return;

        if (!bGoingThroughHose)
        {
			VacuumableComp.bCanEnterVacuum = false;
			DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			BP_StopLaunch();
			bLanded = false;
			bBeingLaunched = false;
			bShot = false;
			bDestroyed = true;
            Niagara::SpawnSystemAtLocation(ExplosionEffect, ActorLocation);
            OnBombDestroyed.Broadcast(this);
            BombMesh.SetHiddenInGame(true);
			SetActorEnableCollision(false);
			FireEffect.Deactivate();
			BurnEffect.Deactivate();
			SetActorTickEnabled(false);
			DangerZoneDecal.SetHiddenInGame(true);
			HazeAkComp.HazePostEvent(ImpactEvent);
			HazeAkComp.HazePostEvent(ExploEvent);
			HazeAkComp.SetRTPCValue("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", -10.f);

        }
    }

	UFUNCTION(BlueprintEvent)
	void BP_StopLaunch() {}

	UFUNCTION(BlueprintEvent)
	void BP_ResetSuckability() {}
}