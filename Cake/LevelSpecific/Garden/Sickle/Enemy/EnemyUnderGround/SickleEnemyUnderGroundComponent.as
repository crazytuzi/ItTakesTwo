import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent;
import Peanuts.Health.BossHealthBarWidget;

event void FSickleUnderGroundEnemyBulletImpactEvent(ASickleUnderGroundEnemyBullet Bullet, FHitResult Hit);

struct FSickleEnemyUnderGroundPassiveDamageData
{
	FVector ImpactLocation;
	float StartRadius;
	float Radius;
	float StartLifeTime;
	float LifeTimeLeft;
}

class USickleEnemyUnderGroundComponent : USickleEnemyComponentBase
{
	default MovementSpeed = 600.f;
	default AttackDistance = 15000;
	default DetectMayDistance = 700.f;
	default DetectCodyDistance = 1500.f;
	default AttackImpactRadius = 0.f;
	default StrayFromHomeDistance = 300.f;
	default StayAtReachedTargetTime = FHazeMinMax(2.f, 3.f);
	default AttackMovementRotationSpeed = 10.f;
	default SickleDeathDelay = 1.5f;
	default bDepenetrateOutOfOtherMovementComponents = false;

	default ControlSideDefaultCollisionSolver = n"NoCollisionSolver";
	default RemoteSideDefaultCollisionSolver = n"NoCollisionSolver";

	// Played when the enemy goes underground
	UPROPERTY(Category = "Effects")
	UNiagaraSystem BurrowEffect;

	// Shown when the enemy Shows the head
	UPROPERTY(Category = "Effects")
	UNiagaraSystem ShowHeadEffect;

	// Triggers when the enemy is exposed from the vine attach, or when it starts shooting
	UPROPERTY(Category = "Effects")
	UNiagaraSystem ShowBodyEffect;

	// Triggers when the enemy is exposed from the vine attach, or when it starts shooting
	UPROPERTY(Category = "Effects")
	UNiagaraSystem ShowBodyLoopEffect;

	UPROPERTY()
	UGardenVegetablePatchVOBank VOBank;

	// Shown the enemy moves
	UPROPERTY(Category = "Effects")
	UNiagaraSystem StartMoveUndergroundEffect;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem MoveUndergroundLoopEffect;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem StopMoveUndergroundEffect;

	UPROPERTY(Category = "Movement")
	FCollisionProfileName UnderGroundMovementProfile;

	// How much the movespeed will increase when ai is in ragemode
	UPROPERTY(Category = "Movement")
	float RageMoveSpeedMultiplier = 3.f;

	// How far from the current moveto location, the actor can change to a new location
	UPROPERTY(Category = "Movement")
	FHazeMinMax RagePickNewMovetoLocationDistance = FHazeMinMax(10.f, 1000.f);

	UPROPERTY(EditDefaultsOnly, Category = "Combat")
	FText BossName = NSLOCTEXT("Burrower", "Name", "Ungerground Nightmare");

	UPROPERTY(EditDefaultsOnly, Category = "Combat")
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBarWidget;

	UPROPERTY(Category = "Combat")
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY(Category = "Combat")
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(Category = "Combat")
	int DamageAmount = 1;

	// How offset from the player towards the burrower it is going to aim
	UPROPERTY(Category = "Combat")
	float ShootAtOffset = 300.f;

	// How long from the impact location are players going to be affected
	UPROPERTY(Category = "Combat")
	float ImpactRadius = 300.f;

	// How long cody needs to hold before the enemy is pulled out of the ground
	UPROPERTY(Category = "Combat", meta = (ClampMin = "0.01"))
	float TimeRequiredToPullOutOfGround = 0.6f;

	UPROPERTY(Category = "Combat|Bullet")
	TSubclassOf<ASickleUnderGroundEnemyBullet> BulletClass;

	UPROPERTY(Category = "Combat|Bullet")
	const float InitialShotDelay = 1.2f;
	
	// How long cooldown between bullets
	UPROPERTY(Category = "Combat|Bullet", meta = (ClampMin = "0.01"))
	float DelayBetweenBullets = 0.5f;

	UPROPERTY(Category = "Combat|Bullet")
	int BulletsToShoot = 3;

	// How long until the enemy can shoot again
	UPROPERTY(Category = "Combat|Bullet", meta = (ClampMin = "0.01"))
	float DelayToNextAttack = 4.0f;

	// How fast the bullet moves
	UPROPERTY(Category = "Combat|Bullet", meta = (ClampMin = "1.0"))
	float BulletMovementSpeed = 2200.f;

	// How long until the bullet is destroyed if it dont hit anything
	UPROPERTY(Category = "Combat|Bullet", meta = (ClampMin = "1.0"))
	float BulletLifeTime = 10.f;

	bool bCodyWantsMeToHide  = false;
	bool bMayWantsMeToHide  = false;

	private FCollisionProfileName InternalOriginalCollisionProfile;
	private TArray<UObject> ShowHeadInstigators;
	private TArray<UObject> ShowBodyInstigators;
	private ASickleEnemy AiOwner;

	private float DebugLastOffsetAmount = 0;
	private int IgnorePlayersWhenMovingCounter = 0;
	private UVineImpactComponent VineImpactComp;
	private USickleEnemySpawnManagerComponent SpawnManager;
	private UNiagaraComponent UprootedLoopEffect;

	int SpawnedAmount = 0;

	float CustomMayDetectionDistance = -1;
	TArray<FSickleEnemyUnderGroundPassiveDamageData> PassiveGroundDamageLocations;
	float AttackDelay = 0.f;
	
	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		Super::BeginPlay();
		AiOwner = Cast<ASickleEnemy>(Owner);
		Setup(AiOwner.CapsuleComponent);
		VineImpactComp = UVineImpactComponent::Get(AiOwner);
		VineImpactComp.SetCanActivate(false, this);
		InternalOriginalCollisionProfile = TraceParams::GenerateCollisionProfileName(AiOwner.CapsuleComponent.GetCollisionProfileName());
		AiOwner.BlockCapabilities(n"HealthWidget", this);
		SpawnManager = USickleEnemySpawnManagerComponent::Get(Owner);
		if(SpawnManager != nullptr)
			SpawnManager.OnEnemySpawned.AddUFunction(this, n"OnChildSpawned");
	}

	UFUNCTION()
	void AddHealthBar(int HealthSegments = 3)
	{
		HealthBarWidget = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarClass));
		const float MaxHealth = float(USickleCuttableHealthComponent::Get(AiOwner).MaxHealth);
		HealthBarWidget.InitBossHealthBar(BossName, MaxHealth, HealthSegments);
		HealthBarWidget.SnapHealthTo(MaxHealth);

		auto SickleCuttableComp = USickleCuttableComponent::Get(Owner);
		SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"OnSickleDamageReceived");
	}

	UFUNCTION()
	void RemoveHealthBar()
	{
		if (HealthBarWidget == nullptr)
			return;

		Widget::RemoveFullscreenWidget(HealthBarWidget);
		HealthBarWidget = nullptr;

		auto SickleCuttableComp = USickleCuttableComponent::Get(Owner);
		SickleCuttableComp.OnCutWithSickle.UnbindObject(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSickleDamageReceived(int DamageAmount)
	{
		if(HealthBarWidget != nullptr)
			HealthBarWidget.TakeDamage(DamageAmount);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnChildSpawned(ASickleEnemy Enemy)
	{
		FVector ActorSetLocation = FVector::ZeroVector;
		const float Distance = FMath::RandRange(200.f, 2000.f);
		if(AiOwner.GetRandomLocationInShape(ActorSetLocation, Distance))
		{
			Enemy.SetActorLocationAndRotation(ActorSetLocation, FRotator(0.f, FMath::RandRange(-180, 180), 0.f));
		}

		SpawnedAmount++;
		if(SpawnedAmount >= SpawnManager.MaxAmount)
		{
			SpawnManager.DisableSpawning();
		}
	}

	void EnableSpawning()
	{
		if(!AiOwner.IsAlive())
			return;

		if(SpawnedAmount >= SpawnManager.MaxAmount)
		{
			SpawnManager.ResetSpawnCount();
			SpawnedAmount = 0;
		}

		SpawnManager.EnableSpawning();
	}

	protected void Crumb_ChangeControlSide(FHazeDelegateCrumbData CrumbData) override
	{
		CurrentPlayerTarget = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		// we never change controlside on the burrower
	}

	FName GetOriginalCollisionProfile() const property
	{
		return Trace::GetCollisionProfileName(InternalOriginalCollisionProfile);
	}

	void Killed() override
	{
		Super::Killed();

		if(UprootedLoopEffect != nullptr)
		{
			UprootedLoopEffect.Deactivate();
			UprootedLoopEffect.DestroyComponent(this);
			UprootedLoopEffect = nullptr;
		}
				
	}

	void ShowHead(UObject Instigator)
	{
		if(ShowHeadInstigators.Contains(Instigator))
			return;

		

		ShowHeadInstigators.Add(Instigator);

		if(ShowHeadInstigators.Num() == 1)
		{
			VineImpactComp.SetCanActivate(false, this);
			if(ShowHeadEffect != nullptr)
				Niagara::SpawnSystemAtLocation(ShowHeadEffect, AiOwner.GetActorLocation());

			// Notify Burrower audio capability
			{
				AiOwner.SetCapabilityActionState(n"AudioOnShowHead", EHazeActionState::ActiveForOneFrame);
			}
		}
	}

	void ShowBody(UObject Instigator)
	{
		if(ShowBodyInstigators.Contains(Instigator))
			return;

		ShowBodyInstigators.Add(Instigator);

		// Always show the body height if that is what we want
		VineImpactComp.SetCanActivate(true, this);

		if(ShowBodyInstigators.Num() == 1)
		{
			if(ShowBodyEffect != nullptr)
				Niagara::SpawnSystemAtLocation(ShowBodyEffect, AiOwner.GetActorLocation());

			if(!bHasBeenKilled)
			{
				if(UprootedLoopEffect == nullptr)
					UprootedLoopEffect = Niagara::SpawnSystemAttached(ShowBodyLoopEffect, AiOwner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);

				if(UprootedLoopEffect != nullptr)
					UprootedLoopEffect.Activate(true);
			}

			AiOwner.UnblockCapabilities(n"HealthWidget", this);

			// Notify Burrower audio capability
			{
				AiOwner.SetCapabilityActionState(n"AudioOnShowHead", EHazeActionState::ActiveForOneFrame);
			}
		}	
	}

	bool IsShowingBody() const
	{
		return ShowBodyInstigators.Num() > 0;
	}

	void RemoveMeshOffsetInstigator(UObject Instigator)
	{
		const bool bHadShowBodyInstigator = ShowBodyInstigators.Num() > 0;

		PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenVegetablePatchBurrowerWhipHint");

		// Check if this is a valid instigator still
		bool bFound = ShowHeadInstigators.Remove(Instigator);
		if(!bFound)
			bFound = ShowBodyInstigators.Remove(Instigator);
		if(!bFound)
			return;

		if(ShowBodyInstigators.Num() == 0)
		{
			if(bHadShowBodyInstigator)
				AiOwner.BlockCapabilities(n"HealthWidget", this);

			if(UprootedLoopEffect != nullptr)
				UprootedLoopEffect.Deactivate();

			// We only want to show the head
			if(ShowHeadInstigators.Num() > 0)
			{
				VineImpactComp.SetCanActivate(false, this);
			}
			// We want to hide
			else
			{
				VineImpactComp.SetCanActivate(false, this);

				if(BurrowEffect != nullptr)
					Niagara::SpawnSystemAtLocation(BurrowEffect, AiOwner.GetActorLocation());
				
				// Notify Burrower audio capability
				{
					AiOwner.SetCapabilityActionState(n"AudioOnBurrow", EHazeActionState::ActiveForOneFrame);
				}
			}
		}
	}

	void IgnorePlayersWhenMoving()
	{
		if(IgnorePlayersWhenMovingCounter == 0)
		{
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for(auto Player : Players)
			{
				StartIgnoringActor(Player);
			}		
		}
		IgnorePlayersWhenMovingCounter++;	
	}

	void IncludePlayersWhenMoving()
	{
		IgnorePlayersWhenMovingCounter--;
		if(IgnorePlayersWhenMovingCounter == 0)
		{
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for(auto Player : Players)
			{
				StopIgnoringActor(Player);
			}		
		}
	}

	float GetDetectDistance(AHazePlayerCharacter Player) const
	{
		if(Player.IsMay())
		{
			if(CustomMayDetectionDistance >= 0)
				return CustomMayDetectionDistance;
			return DetectMayDistance;
		}
		else
		{
			return DetectCodyDistance;
		}
	}
}

// Used to determain from where to shoot
UCLASS()
class USickleUnderGroundEnemyBulletSpawnLocation : USceneComponent
{

}

// The bullet that is going to get shot
UCLASS(Abstract)
class ASickleUnderGroundEnemyBullet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"BlockAll");
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Effect;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = false;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactEffect;

	UPROPERTY(EditDefaultsOnly)
	float CollisionRadius = 30.f;

	TArray<AActor> IgnoreActors;
	FHitResult PendingHitResult;
	
	private float MovemenetSpeed = 0;
	private float CurrentLifeTime = 0;
	private float LifeTimeLeft = 0;
	private float TriggerImpactAtLifeTime = -1;	
	private FVector DirToShoot;
	private bool _IsMoving = false;

	UPROPERTY()
	FSickleUnderGroundEnemyBulletImpactEvent OnImpact;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(_IsMoving)
		{
			CurrentLifeTime += DeltaSeconds;
			LifeTimeLeft -= DeltaSeconds;

			const FVector LastLocation = GetActorLocation();

			FVector NewLocation = LastLocation + (DirToShoot * MovemenetSpeed * DeltaSeconds);
			
			//System::DrawDebugSphere(GetActorLocation(), 50.f);

			FHazeHitResult Hit;
			FHazeTraceParams TraceParams;
			TraceParams.InitWithPrimitiveComponent(Collision);
			TraceParams.IgnoreActors(IgnoreActors);
			TraceParams.From = LastLocation;
			TraceParams.To = NewLocation;
			
			if(TraceParams.Trace(Hit))
			{
				NewLocation = Hit.ImpactPoint;
				AHazePlayerCharacter ImpactPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(ImpactPlayer != nullptr && ImpactPlayer.HasControl())
				{
					NetTriggerImpact(Hit, CurrentLifeTime);
				}
				else if(HasControl())
				{
					NetTriggerImpact(Hit, CurrentLifeTime);
				}
			}

			SetActorLocation(NewLocation);

			if(CurrentLifeTime >= TriggerImpactAtLifeTime && TriggerImpactAtLifeTime >= 0)
			{
				OnImpact.Broadcast(this, PendingHitResult);
			}
			else if(LifeTimeLeft < 0)
			{
				OnImpact.Broadcast(this, FHitResult());
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetTriggerImpact(FHazeHitResult Hit, float AtLifeTime)
	{
		TriggerImpactAtLifeTime = AtLifeTime;
		PendingHitResult = Hit.FHitResult;
	}

	bool IsMoving() const
	{
		return _IsMoving;
	}

	void InitializeShot(FVector Location, FRotator Rotation, FVector _DirToShoot, float LifeTime, float _MovementSpeed)
	{
		_IsMoving = true;
		SetActorLocationAndRotation(Location, Rotation);
		MovemenetSpeed = _MovementSpeed;
		CurrentLifeTime = 0;
		LifeTimeLeft = LifeTime;
		DirToShoot = _DirToShoot;

	}

	void ResetBullet()
	{
		CurrentLifeTime = 0;
		LifeTimeLeft = 0;
		_IsMoving = false;
		TriggerImpactAtLifeTime = -1;
		PendingHitResult = FHitResult();
	}
}
