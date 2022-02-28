
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;

event void FSickleAirEnemyBombImpactEvent(ASickleAirEnemyBomb Bomb, FVector ImpactPoint);

class USickleEnemyAirComponent : USickleEnemyComponentBase
{
	default MovementSpeed = 100.f;
	default MovementRotationSpeed = 2.f;
	default AttackDistance = 600.f;
	default WhipHit.StunnedDuration = 0.5f;

	default DetectMayDistance = 2500.f;
	default DetectCodyDistance = 2500.f;

	default ControlSideDefaultCollisionSolver = n"AICharacterAirborneDetectionSolver";
	default RemoteSideDefaultCollisionSolver = n"AICharacterAirborneDetectionSolver";

	UPROPERTY(Category = "Movement")
	float FlyHeight = 400.f;

	UPROPERTY(Category = "Movement")
	FCollisionProfileName GroundTraceChannel;

	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float VineLockedMoveToGroundSpeed = 1200.f;

	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float AscendingMoveSpeed = 400.f;

	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float DescendingMoveSpeed = 400.f;

	UPROPERTY(Category = "Combat")
	TSubclassOf<UPlayerDamageEffect> DamageEffect;
	
	UPROPERTY(Category = "Combat")
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(Category = "Combat")
	int DamageAmount = 1;

	UPROPERTY(Category = "Combat")
	float SelectableDistanceInAir = -1.f;

	UPROPERTY(Category = "Combat")
	float MaxLockedByVineTime = 3;

	UPROPERTY(Category = "Combat|Bomb", meta = (ClampMin = "0"), EditDefaultsOnly)
	int BombAmount = 5;

	UPROPERTY(Category = "Combat|Bomb", EditDefaultsOnly, meta = (EditCondition="BombAmount > 0"))
	TSubclassOf<ASickleAirEnemyBomb> BombClass;

	UPROPERTY(Category = "Combat|Bomb", EditDefaultsOnly, meta = (EditCondition="BombAmount > 0"))
	FRuntimeFloatCurve DropBombMovementSpeed;

	// How fast the actor rotate when it attack moves
	UPROPERTY(Category = "Combat|Bomb", EditDefaultsOnly, meta = (EditCondition="BombAmount > 0"))
	float DropBombMovementRotationSpeed = 1.f;
	
	// The attackdistance + this will end the bombing run
	UPROPERTY(Category = "Combat|Bomb", EditDefaultsOnly, meta = (EditCondition="BombAmount > 0"))
	float StopBombingAttackBonusDistance = 200.f;

	UPROPERTY(Category = "Combat|Bomb", meta = (ClampMin = "0.01"), EditDefaultsOnly, meta = (EditCondition="BombAmount > 0"))
	float InitialBombDelay = 0.2f;

	UPROPERTY(Category = "Combat|Bomb", meta = (ClampMin = "0.01"), EditDefaultsOnly, meta = (EditCondition="BombAmount > 0"))
	float DelayBetweenBombs = 0.3f;

	UPROPERTY(Category = "Combat|Dodge", EditDefaultsOnly)
	bool bDodgePlayer = false;

	UPROPERTY(Category = "Combat|Dodge", meta = (EditCondition = "bDodgePlayer"))
	TSubclassOf<UHazeCapability> DodgeCapability;

	// The effect that is played when the bomb hits something
	UPROPERTY(Category = "Effects", EditDefaultsOnly)
	UNiagaraSystem ImpactEffect;

	// The effect that is played when this becomes grounded
	UPROPERTY(Category = "Effects", EditDefaultsOnly)
	UNiagaraSystem GroundedEffect;

	// The effect that is played when this becomes grounded
	UPROPERTY(Category = "Effects", EditDefaultsOnly)
	UNiagaraSystem MoveAwayFromGroundEffect;

	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	TSubclassOf<UHazeCollisionSolver> CustomControlCollisionSolver;

	private float InternalOriginalSelectableDistance = 0;
	float CurrentFlyHeight = -1;
	TArray<ASickleAirEnemyBomb> BombContainer;

	ASickleEnemy EnemyOwner;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		Super::BeginPlay();
		EnemyOwner = Cast<ASickleEnemy>(Owner);
		Setup(EnemyOwner.CapsuleComponent);

		if(CustomControlCollisionSolver.IsValid())
			UseCollisionSolver(CustomControlCollisionSolver, nullptr);

		InternalOriginalSelectableDistance = EnemyOwner.SickleCuttableComp.GetDistance(EHazeActivationPointDistanceType::Selectable);

		if(bDodgePlayer && DodgeCapability.IsValid())
		{
			EnemyOwner.AddCapability(DodgeCapability);
		}

		// Begin with finding the ground so we know where it is
		const float TraceDistance = FlyHeight * 4.f;
		FHazeHitResult GroundTrace;
		if(TraceGround(Owner.GetActorLocation(), GroundTrace))
		{
			if(GroundTrace.bBlockingHit)
				CurrentFlyHeight = GroundTrace.Distance;	
		}
	}

	float GetOriginalSelectableDistance() const
	{
		return InternalOriginalSelectableDistance;
	}

	void ApplyFlyHeightMovement(float DeltaTime, FVector CurrentFlyLocation, FHazeFrameMovement& FinalMovement)
	{
		// The ai is never going to change worldup so I skip that calculation
		const float TraceDistance = FlyHeight * 4.f;

		FHazeHitResult GroundTrace;
		const bool bFoundGround = TraceGround(CurrentFlyLocation, GroundTrace);
		if(!bFoundGround)
		{
			FinalMovement.ApplyVelocity(-FVector::UpVector * TraceDistance);
			return;
		}
		
		FVector WantedFlyLocation = CurrentFlyLocation;
		WantedFlyLocation.Z = GroundTrace.ImpactPoint.Z;
		WantedFlyLocation.Z += FlyHeight;
		
		if(bDodgePlayer)
		{
			auto May = Game::GetMay();
			const float HorizontalDistance = Owner.GetHorizontalDistanceTo(May);
			const float HeightAlpha = FMath::Min(HorizontalDistance / AttackDistance, 1.f);
			if(HeightAlpha < 1.f)
			{
				WantedFlyLocation.Z += FMath::Lerp(0.f, May.GetCollisionSize().Y * 6, HeightAlpha);
			}
		}

		const float DotToUp = (WantedFlyLocation - CurrentFlyLocation).GetSafeNormal().DotProduct(FVector::UpVector);
		
		// We want to go up
		if(DotToUp > 0)
		{
			WantedFlyLocation.Z = FMath::FInterpConstantTo(CurrentFlyLocation.Z, WantedFlyLocation.Z, DeltaTime, AscendingMoveSpeed);
		}
		// We want to go down
		else if(DotToUp < 0)
		{
			WantedFlyLocation.Z = FMath::FInterpConstantTo(CurrentFlyLocation.Z, WantedFlyLocation.Z, DeltaTime, DescendingMoveSpeed);
		}

		// Ignore velocty going up and down
		FinalMovement.ApplyDeltaWithCustomVelocity(WantedFlyLocation - CurrentFlyLocation, FVector::ZeroVector);
		if(GroundTrace.bBlockingHit)
			CurrentFlyHeight = GroundTrace.Distance;
		else
			CurrentFlyHeight = -1;
	}

	bool TraceGround(FVector CurrentFlyLocation, FHazeHitResult& OutResult)
	{
		const float TraceDistance = FlyHeight * 4.f;

		FHazeTraceParams GroundTraceParams;
		GroundTraceParams.InitWithCollisionProfile(GroundTraceChannel);
		GroundTraceParams.IgnoreActor(Owner);
		GroundTraceParams.SetToLineTrace();
		GroundTraceParams.From = CurrentFlyLocation;
		GroundTraceParams.From += FVector::UpVector * EnemyOwner.GetCollisionSize().Y;
		GroundTraceParams.To = GroundTraceParams.From;
		GroundTraceParams.To -= FVector::UpVector * TraceDistance;

		return GroundTraceParams.Trace(OutResult);
	}
}

UCLASS(Abstract)
class ASickleAirEnemyBombDecalIndicator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent Decal;

	UMaterialInstanceDynamic MaterialInstance;
	float ActiveTime = 0;
	float DangeTime = 0;
	float DestroyMeTimeLeft = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MaterialInstance = Decal.CreateDynamicMaterialInstance();
		ActiveTime = 0.f;
	}

	void PrepareDestroy()
	{
		DestroyMeTimeLeft = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DestroyMeTimeLeft > 0)
		{
			DestroyMeTimeLeft = FMath::FInterpConstantTo(DestroyMeTimeLeft, 0.f, DeltaSeconds, 4.f);
			if(DestroyMeTimeLeft <= 0)
				DestroyActor();
			else
				MaterialInstance.SetScalarParameterValue(n"Time", DestroyMeTimeLeft);
		}
		else
		{
			ActiveTime = FMath::FInterpConstantTo(ActiveTime, 1.f, DeltaSeconds, 4.f);
			MaterialInstance.SetScalarParameterValue(n"Time", ActiveTime);

			if(ActiveTime >= 1.f)
			 	DangeTime = FMath::FInterpConstantTo(DangeTime, 1.f, DeltaSeconds, 4.f);

			MaterialInstance.SetScalarParameterValue(n"DangerClose", 1.f);
		}		
	}
}

// The bomb that is used by the air enemy
UCLASS(Abstract)
class ASickleAirEnemyBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
    UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = false;
	default DisableComponent.bDisabledAtStart = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASickleAirEnemyBombDecalIndicator> ImpactType;
	
	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComponent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent BlobExploAudioEvent;

	UPROPERTY()
    FSickleAirEnemyBombImpactEvent OnBombImpact;

	FVector CurrentVelocity;
	FHazeTraceParams TraceParams;

	bool bIsMoving = false;
	bool bIsShowingDecal = false;
	ASickleAirEnemyBombDecalIndicator ActiveDecal;

	FVector LastTraceLocation;
	float LastTraceTime = 0;

	ASickleEnemy AiOwner;
	float MovingTime = 0;

	UFUNCTION(BlueprintEvent)
	void Initialize()
	{

	}
	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(ActiveDecal != nullptr)
			ActiveDecal.PrepareDestroy();

		ActiveDecal = nullptr;
	}

	void DropBomb(USickleEnemyAirComponent AiComponent, AHazePlayerCharacter ControlSide)
	{
		// Force the bomb to reset if it is still active
		if(HasControl() != ControlSide.HasControl())
			SetControlSide(ControlSide);

		if(!bIsMoving)
			EnableActor(AiOwner);

		if(!bIsShowingDecal && ImpactType.IsValid())
		{
			FHazeHitResult DecalHit;
			if (AiComponent.TraceGround(AiComponent.Owner.GetActorLocation(), DecalHit))
			{
				bIsShowingDecal = true;
				ActiveDecal = Cast<ASickleAirEnemyBombDecalIndicator>(SpawnActor(ImpactType, DecalHit.ImpactPoint));
				ActiveDecal.SetActorLocation(DecalHit.ImpactPoint);
			}
		}

		SetActorLocation(AiOwner.GetActorLocation());	
		CurrentVelocity = FVector::ZeroVector;
		bIsMoving = true;
		LastTraceLocation = GetActorLocation();
		LastTraceTime = Time::GetGameTimeSeconds();
		MovingTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsMoving)
		{
			MovingTime += DeltaSeconds;
			const FVector CurrentActorLocation = GetActorLocation();
			CurrentVelocity -= FVector::UpVector * 80.f * DeltaSeconds; 
			SetActorLocation(CurrentActorLocation + CurrentVelocity);

			if(HasControl())
			{
				if(Time::GetGameTimeSeconds() >= LastTraceTime + 0.2f
				|| LastTraceLocation.DistSquared(GetActorLocation()) > FMath::Square(50.f))
				{
					FHazeHitResult Hit;
					TraceParams.From = LastTraceLocation;
					TraceParams.To = GetActorLocation();
					LastTraceLocation = TraceParams.To;
					LastTraceTime = Time::GetGameTimeSeconds();
					if (TraceParams.Trace(Hit))
					{
						SetActorLocation(Hit.ImpactPoint);	
						
						FHazeDelegateCrumbParams CrumbParams;
						CrumbParams.AddVector(n"ImpactPoint", Hit.ImpactPoint + (Hit.ImpactNormal * 10));
						AiOwner.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_BombImpact"), CrumbParams);
					}
				}

				if(bIsMoving && MovingTime > 3.f)
				{
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddVector(n"ImpactPoint", GetActorLocation());
					AiOwner.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_BombImpact"), CrumbParams);
				}
			}
		}	
	}
	
	UFUNCTION(NotBlueprintCallable)
	void Crumb_BombImpact(const FHazeDelegateCrumbData& CrumbData)
	{
		FVector ImpactPoint = CrumbData.GetVector(n"ImpactPoint");
		OnBombImpact.Broadcast(this, ImpactPoint);
		DisableActor(AiOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		if(ActiveDecal != nullptr)
			ActiveDecal.PrepareDestroy();

		ActiveDecal = nullptr;
		bIsShowingDecal = false;
		CurrentVelocity = FVector::ZeroVector;
		bIsMoving = false;

		return false;
	}
}