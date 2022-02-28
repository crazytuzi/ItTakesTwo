import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyUnderGround.SickleEnemyUnderGroundComponent;

class USickleEnemyUnderGroundShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 101;

	ASickleEnemy AiOwner;
	USickleEnemyUnderGroundComponent AiComponent;

	TArray<ASickleUnderGroundEnemyBullet> BulletContainer;
	USickleUnderGroundEnemyBulletSpawnLocation BulletSpawnLocation;
	int CurrentBulletContainerIndex = 0;
	float TimeToInitialShot = 0;
	float TimeToShoot = 0;
	int BulletsLeftToShoot = 0;
	
	float TimeToDisable = 0;
	AHazePlayerCharacter CurrentTarget;

	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString Str = "";
		Str += "Initial Cooldown: " + TimeToInitialShot + "\n";
		Str += "Bullets: " + BulletsLeftToShoot + "\n";
		Str += "TimeToShoot: " + TimeToShoot + "\n";
		Str += "TimeToDisable: " + TimeToDisable + "\n";
        return Str;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyUnderGroundComponent::Get(Owner);
		BulletSpawnLocation = USickleUnderGroundEnemyBulletSpawnLocation::GetOrCreate(Owner);

		// Create the bullets and make them networked
		const int MaxBullets = AiComponent.BulletsToShoot;
		for(int i = 0; i < MaxBullets; ++i)
		{
			auto Projectile = Cast<ASickleUnderGroundEnemyBullet>(SpawnActor(AiComponent.BulletClass, AiOwner.GetActorLocation(), Level = Owner.GetLevel()));
			Projectile.MakeNetworked(this, i);
			Projectile.SetActorEnableCollision(false);
			Projectile.IgnoreActors.Add(AiOwner);
			
			BulletContainer.Add(Projectile);
			Projectile.DisableActor(AiOwner);
			Projectile.OnImpact.AddUFunction(this, n"OnBulletImpact");
			Projectile.AttachToComponent(AiOwner.RootComponent);
			if(AiComponent != nullptr)
			{
				AiComponent.StartIgnoringActor(Projectile);
			}
		}

		// Bullets can't hit eachother
		for(int i = 0; i < MaxBullets; ++i)
		{
			for(int ii = 0; ii < MaxBullets; ++ii)
			{
				BulletContainer[i].IgnoreActors.Add(BulletContainer[ii]);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for(auto Bullet : BulletContainer)
		{
			if(Bullet != nullptr)
			{
				Bullet.DestroyActor();
			}
		}
		BulletContainer.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		AiComponent.AttackDelay = FMath::Max(AiComponent.AttackDelay - DeltaTime, 0.f);
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AiComponent.bMayWantsMeToHide)
			return EHazeNetworkActivation::DontActivate;

		if(!AiOwner.CanAttack())
			return EHazeNetworkActivation::DontActivate;

		if(AiComponent.AttackDelay > 0)
			return EHazeNetworkActivation::DontActivate;

		AHazePlayerCharacter WantedTarget = AiOwner.GetCurrentTarget();
		if(WantedTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(AiComponent.bMayWantsMeToHide)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(AiOwner.bIsBeeingHitByVine)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BulletsLeftToShoot > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(TimeToDisable > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Player", AiOwner.GetCurrentTarget());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentTarget = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"Player"));
		AiOwner.LockPlayerAsTarget(CurrentTarget);
		AiComponent.ShowBody(this);
		
		AiOwner.bAttackingPlayer = true;
		AiOwner.LastAttackTime = Time::GetGameTimeSeconds();
		AiOwner.BlockMovementWithInstigator(this);
		AiComponent.CustomMayDetectionDistance = 500.f;
		TimeToInitialShot = AiComponent.InitialShotDelay;
		BulletsLeftToShoot = AiComponent.BulletsToShoot;
		TimeToDisable = 2.5f;
		TimeToShoot = 0;

		const FVector LocationToHit = CurrentTarget.GetActorLocation();
		const FVector DirToFace = (LocationToHit - AiOwner.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		// Pick a random position to shoot at to try and hit the player better
		if(DirToFace.SizeSquared() > 0)
			AiComponent.SetTargetFacingDirection(DirToFace, 6.f);

		AiOwner.CapsuleComponent.SetCollisionProfileName(Trace::GetCollisionProfileName(AiComponent.UnderGroundMovementProfile));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiComponent.RemoveMeshOffsetInstigator(this);
		AiOwner.SetFreeTargeting();
		AiOwner.UnblockMovementWithInstigator(this);
		AiOwner.bAttackingPlayer = false;
		AiComponent.CustomMayDetectionDistance = -1;
		AiComponent.AttackDelay = AiComponent.DelayToNextAttack;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"SickleEnemyUnderGroundShootMovement");
		FinalMovement.OverrideStepDownHeight(50.f);

		if(HasControl())
		{
			if(AiComponent.CanCalculateMovement())
			{
				FVector TargetPlayerLocation = CurrentTarget.GetActorLocation();
				FVector DirToPlayer = (TargetPlayerLocation - AiOwner.GetActorLocation()).ConstrainToPlane(AiComponent.WorldUp).GetSafeNormal();
				if(!DirToPlayer.IsNearlyZero())
					AiComponent.SetTargetFacingDirection(DirToPlayer, 30.f);
					
				FinalMovement.ApplyTargetRotationDelta();
				AiComponent.Move(FinalMovement);
				AiOwner.CrumbComponent.LeaveMovementCrumb();
			}
		
			TimeToInitialShot = FMath::Max(TimeToInitialShot - DeltaTime, 0.f);
			if(TimeToInitialShot <= 0 && BulletsLeftToShoot > 0)
			{
				if(TimeToShoot <= 0)
					ShootBullet();

				TimeToShoot -= DeltaTime;	
			}
			else
			{
				TimeToDisable -= DeltaTime;
			}

		}
		else if(AiComponent.CanCalculateMovement())
		{
			FHazeActorReplicationFinalized ReplicationData;
			AiOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ReplicationData);
			FinalMovement.ApplyConsumedCrumbData(ReplicationData);
			AiComponent.Move(FinalMovement);
		}	
	}

	void ShootBullet()
	{
		BulletsLeftToShoot--;
		TimeToShoot += AiComponent.DelayBetweenBullets;
					
		FVector LocationToHit = CurrentTarget.GetActorCenterLocation();
		LocationToHit.Z = AiOwner.GetActorLocation().Z;
		FVector ActorVelocity = CurrentTarget.GetActorVelocity();
		ActorVelocity = ActorVelocity.ConstrainToPlane(FVector::UpVector);
		FVector DirToShootAt = AiOwner.GetActorForwardVector();

		// Pick a random position to shoot at to try and hit the player better
		float DistanceToTarget = LocationToHit.Distance(AiOwner.GetActorLocation());
		if(DistanceToTarget > 0)
		{
			const float TimeToTarget = DistanceToTarget / AiComponent.BulletMovementSpeed;
			LocationToHit += ActorVelocity * TimeToTarget * FMath::RandRange(0.4f, 0.6f);
			LocationToHit += (AiOwner.GetActorLocation() - LocationToHit).ConstrainToPlane(FVector::UpVector).GetSafeNormal() * AiComponent.ShootAtOffset;
			DirToShootAt = (LocationToHit - BulletSpawnLocation.GetWorldLocation()).GetSafeNormal();
		}

		AiComponent.SetTargetFacingDirection(DirToShootAt);

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddVector(n"ShootDirection", DirToShootAt);
		AiOwner.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ShootBullet"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBulletImpact(ASickleUnderGroundEnemyBullet Bullet, FHitResult Hit)
	{
		FVector ImpactLocation = Hit.ImpactPoint;
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			if(!Player.HasControl())
				continue;

			if(Player.GetActorLocation().DistSquared(ImpactLocation) > FMath::Square(AiComponent.ImpactRadius))
				continue;

			// This is already networked
			auto HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		 	const float DamageAmount = float(AiComponent.DamageAmount) / float(HealthSettings.HealthChunks);
		 	Player.DamagePlayerHealth(DamageAmount, AiComponent.DamageEffect, AiComponent.DeathEffect);
		}

		if(Bullet.ImpactEffect != nullptr)
			Niagara::SpawnSystemAtLocation(Bullet.ImpactEffect, Bullet.GetActorLocation(), FRotator::ZeroRotator);

		AiOwner.SetCapabilityAttributeVector(n"AudioOnProjectileImpact", ImpactLocation);
		Bullet.DisableActor(AiOwner);
		Bullet.AttachToComponent(AiOwner.RootComponent);
		Bullet.SetActorEnableCollision(false);
		Bullet.ResetBullet();
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_ShootBullet(const FHazeDelegateCrumbData& CrumbData)
	{
		auto Bullet = BulletContainer[CurrentBulletContainerIndex];

		// Reset the bullet if it is currently moving
		if(Bullet.IsMoving())
		{
			Bullet.ResetBullet();
		}
		else
		{
			Bullet.SetActorEnableCollision(true);
			Bullet.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			Bullet.EnableActor(AiOwner);
		}

		FVector DirToShoot = CrumbData.GetVector(n"ShootDirection");
		if(DirToShoot.IsNearlyZero())
			DirToShoot = AiOwner.GetActorForwardVector();

		AiComponent.SetTargetFacingDirection(DirToShoot, 30.f);
		Bullet.InitializeShot(
			BulletSpawnLocation.GetWorldLocation(), 
			DirToShoot.ToOrientationRotator(),
			DirToShoot,
			AiComponent.BulletLifeTime,
			AiComponent.BulletMovementSpeed);

		AiOwner.Mesh.SetAnimBoolParam(n"Shoot", true);
		AiOwner.SetCapabilityActionState(n"AudioOnShootProjectile", EHazeActionState::ActiveForOneFrame);

		CurrentBulletContainerIndex++;
		if(CurrentBulletContainerIndex >= BulletContainer.Num())
			CurrentBulletContainerIndex = 0;
	}
}
