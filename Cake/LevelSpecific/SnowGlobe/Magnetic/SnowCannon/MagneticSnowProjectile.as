import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.ShotBySnowCannonComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerDataComponent;

event void FOnSnowCannonProjectileHit(AMagneticSnowProjectile Projectile, FHitResult Hit);

UCLASS(Abstract)
class AMagneticSnowProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"OverlapAll";
	default Mesh.SetbHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FlyTrail;
	
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface RedMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlueMaterial;

	UPROPERTY()
	AActor ParentCannon;

	UPROPERTY()
	FOnSnowCannonProjectileHit OnSnowCannonProjectileHit;

	UPROPERTY()
	bool bIsPositive;


	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY(DefaultComponent)
	UDopplerDataComponent DopplerDataComp;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent Shot;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent Impact;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent SlideStart;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent SlideStop;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent ExploEvent;


	FVector ProjectileVelocity;
	float Gravity = 4000;

	FQuat RotationLerpOrigin;
	FQuat RotationLerpTarget;
	float RotationLerpTime;

	bool bActivated;

	float ProjectileLifeTime = 3.0f;
	float ProjectileTimer = 0.0f;

	FRotator BotchedRotationAcceleration;
	bool bBotchedThrow;

	UFUNCTION()
	void Initialize(AActor ShootingCannon, bool bPositive)
	{
		ParentCannon = ShootingCannon;
		bIsPositive = bPositive;

		if (bIsPositive)
		{
			Mesh.SetMaterial(0, RedMaterial);
		}
		else
		{
			Mesh.SetMaterial(0, BlueMaterial);
		}

		HazeAkComponent.SetTrackVelocity(true, 12500.f);
		HazeAkComponent.SetTrackDistanceToPlayer(true);
	}

	UFUNCTION()
	void ShootProjectile(FVector StartLocation, FQuat StartRotation, FVector TargetLocation, FQuat TargetRotation, FVector InitialVelocity, float ProjectileGravity, bool bValidAimTarget)
	{
		SetActorLocation(StartLocation);
		SetActorRotation(StartRotation);

		ProjectileVelocity = InitialVelocity;
		Gravity = ProjectileGravity;

		bBotchedThrow = !bValidAimTarget;
		if(bBotchedThrow)
		{
			BotchedRotationAcceleration = FRotator(FMath::RandRange(-100.f, 100.f), FMath::RandRange(-120.f, 120.f), FMath::RandRange(-20.f, 20.f));
		}
		else
		{
			RotationLerpOrigin = StartRotation;
			RotationLerpTarget = TargetRotation;
			RotationLerpTime = ActorLocation.Distance(TargetLocation) / InitialVelocity.Size();
		}

		Mesh.SetHiddenInGame(false);
		FlyTrail.Activate();

		// Activate audio component and fire shot event
		HazeAkComponent.HazePostEvent(Shot);

		bActivated = true;
	}

	UFUNCTION()
	void DeactivateProjectile()
	{
		Mesh.SetHiddenInGame(true);
		FlyTrail.Deactivate();
		ProjectileTimer = 0.0f;
		bActivated = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bActivated)
			return;

		TraceForHits(DeltaTime);
		UpdateVelocity(DeltaTime);
		Move(DeltaTime);
		UpdateRotation(DeltaTime);

		ProjectileTimer += DeltaTime;
		if(ProjectileTimer >= ProjectileLifeTime)
			DeactivateProjectile();

		UHazeListenerComponent ClosestListener = UHazeAkComponent::GetClosestListener(World, HazeAkComponent.GetWorldLocation());
		float DistanceToListener = HazeAkComponent.GetWorldLocation().Distance(ClosestListener.GetWorldLocation());
	}

	void UpdateVelocity(float DeltaTime)
	{
		ProjectileVelocity -= FVector(0, 0, Gravity*DeltaTime);
	}

	void Move(float DeltaTime)
	{
		AddActorWorldOffset(ProjectileVelocity*DeltaTime);
	}

	void UpdateRotation(float DeltaTime)
	{
		if(bBotchedThrow)
		{
			AddActorWorldRotation(BotchedRotationAcceleration * DeltaTime * 5.f);
		}
		else
		{
			float Alpha = Math::Saturate(ProjectileTimer / RotationLerpTime);
			SetActorRotation(FQuat::Slerp(RotationLerpOrigin, RotationLerpTarget, Alpha));
		}
	}

	void TraceForHits(float DeltaTime)
	{
		FVector WorldDelta = ProjectileVelocity * DeltaTime;
	
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(ParentCannon);

		FHitResult Hit;
		System::SphereTraceSingle(ActorLocation, ActorLocation + WorldDelta, 50.0f, ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		// There was nothing in the way
		if (!Hit.bBlockingHit)
			return;

		// Event is listened by SnowCannonShootCapability
		OnSnowCannonProjectileHit.Broadcast(this, Hit);

		// Clear and hide projectile
		DeactivateProjectile();
	}

	void PlayImpactAudioEvent(bool bProjectileExploded)
	{
		HazeAkComponent.HazePostEvent(Impact, bStopOnDisable = true);
	}
}