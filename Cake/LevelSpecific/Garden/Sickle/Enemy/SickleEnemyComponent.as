import Vino.Movement.Components.MovementComponent;
import Vino.PlayerHealth.PlayerHealthComponent;


struct FSickleEnemyHit
{
	// The amount it is going to be moved
	UPROPERTY()
	FVector KnockBackAmount = FVector::ZeroVector;

	// How fast the knockback amount is reached
	UPROPERTY()
	float KnockBackHorizontalMovementTime = 0;

	// How long the actor will be stunned after the knockback
	UPROPERTY()
	float StunnedDuration = 0;
};

UCLASS(hidecategories="HazeMovement ComponentReplication Mobile Activation Cooking AssetUserData Collision")
class USickleEnemyComponentBase : UHazeMovementComponent
{
	default bDepenetrateOutOfOtherMovementComponents = false;

	// How fast the actor moves
	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float MovementSpeed = 200.f;

	// How fast the actor rotate when it moves
	UPROPERTY(Category = "Movement", EditDefaultsOnly)
	float MovementRotationSpeed = 4.f;

	// How far from the initial location, the actor can move
	UPROPERTY(Category = "Movement")
	float StrayFromHomeDistance = 400.f;

	// How far from the current moveto location, the actor can change to a new location
	UPROPERTY(Category = "Movement")
	FHazeMinMax PickNewMovetoLocationDistance = FHazeMinMax(100.f, 200.f);

	// How long the actor will linger at the reached location before chaning to a new
	UPROPERTY(Category = "Movement")
	FHazeMinMax StayAtReachedTargetTime = FHazeMinMax(0.f, 0.f);

	// How far from the player the enemy will stand when attacking
	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float AttackDistance = 150.f;

	// When the enemy strikes the player, this is how far the player needs to be to be safe
	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float AttackImpactRadius = 400.f;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float DetectMayDistance = 1500.f;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float DetectCodyDistance = 1000.f;

	// The target can not be changed during this time
	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float ChangeTargetDelayTime = 6.f;

	/* How fast the actor will move to the player
	 * Time is the time from detecting the player
	 * Value is the movespeed
	*/
	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	FRuntimeFloatCurve AttackMovementSpeed;

	// How fast the actor rotate when it attack moves
	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float AttackMovementRotationSpeed = 6.f;

	UPROPERTY(Category = "Combat")
	FSickleEnemyHit SickleImpact;
	default SickleImpact.StunnedDuration = 2.f;

	UPROPERTY(Category = "Combat")
	FSickleEnemyHit WhipHit;
	default WhipHit.StunnedDuration = 1.5f;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float SickleDeathDelay = 0.5f;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float WhipDeathDelay = 0.5f;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float TurretPlantDeathDelay = 0.5f;

	UPROPERTY(EditDefaultsOnly, Category = "Combat")
	bool bIgnoreCodyIfTurretPlantAndBothPlayersAreAlive = true;

	UPROPERTY(Category = "Effects", EditDefaultsOnly)
	UNiagaraSystem DestroyEffect;

	UPROPERTY(Category = "Effects", EditDefaultsOnly, AdvancedDisplay)
	FName DestroyEffectAttachBoneName = n"Hips";


	private TArray<FSickleEnemyHit> PendingImapcts;

	float CanChangeTargetTimeLeft = 0;
	AHazePlayerCharacter CurrentPlayerTarget;
	bool bHasBeenKilled = false;

		
	void SetPlayerAsTargetInternal(AHazePlayerCharacter Player)
	{
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Player", Player);
		auto Crumb = UHazeCrumbComponent::Get(HazeOwner);
		Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ChangeControlSide"), CrumbParams);
		//HazeOwner.CleanupCurrentMovementTrailFromControl(FHazeCrumbDelegate(this, n"Crumb_ChangeControlSide"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_ChangeControlSide(FHazeDelegateCrumbData CrumbData)
	{
		CurrentPlayerTarget = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));

		if(UHazeNetworkControlSideInitializeComponent::Get(Owner) != nullptr)
			return;

		if(CurrentPlayerTarget == nullptr)
			return;

		if(bHasBeenKilled)
			return;

		HazeOwner.SetControlSide(CurrentPlayerTarget);	
	}

	void ApplyHitWithRotation(FSickleEnemyHit Hit, FRotator InstigatorRotation)
	{
		// FVector DebugLog = Owner.GetActorLocation() + (FVector::UpVector * 200);
		// System::DrawDebugArrow(DebugLog, DebugLog + (InstigatorRotation.ForwardVector * 300), LineColor = FLinearColor::Red, Duration = 5.f);

		FSickleEnemyHit ModifiedHit = Hit;
		ModifiedHit.KnockBackAmount = InstigatorRotation.RotateVector(ModifiedHit.KnockBackAmount);
		PendingImapcts.Add(ModifiedHit);

		auto EnemyMovement = UHazeMovementComponent::Get(Owner);
		if(EnemyMovement != nullptr)
			EnemyMovement.StopMovement(true);
	}

	void ApplyHit(FSickleEnemyHit Hit)
	{
		PendingImapcts.Add(Hit);

		auto EnemyMovement = UHazeMovementComponent::Get(Owner);
		if(EnemyMovement != nullptr)
			EnemyMovement.StopMovement(true);
	}

	bool ConsumeHits(FSickleEnemyHit& Out)
	{
		for(int i = 0; i < PendingImapcts.Num(); ++i)
		{
			Out.KnockBackAmount += PendingImapcts[i].KnockBackAmount;
			Out.KnockBackHorizontalMovementTime = FMath::Max(Out.KnockBackHorizontalMovementTime, PendingImapcts[i].KnockBackHorizontalMovementTime);
			Out.StunnedDuration = FMath::Max(Out.StunnedDuration, PendingImapcts[i].StunnedDuration);
		}
		
		PendingImapcts.Empty();
		return Out.KnockBackAmount.SizeSquared() > 1.f || Out.StunnedDuration > 0;
	}

	bool HasHits()const
	{
		return PendingImapcts.Num() > 0;
	}

	void ValidatePositionInCombatArea() {}

	void Killed()
	{
		bHasBeenKilled = true;
	}
}
