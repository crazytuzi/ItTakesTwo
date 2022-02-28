import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;
import Vino.Movement.Helpers.BurstForceStatics;


class USickleEnemyShieldDashCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"SickleEnemyAttack");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 99;
	
	const FHazeMinMax CooldownTimeRange = FHazeMinMax(5.f, 10.f);
	const float DamagePercentage = 1.f/3.f;
	const float ChargeDelay = 0.5f;
	const float ChargeTimeToReachMaxSpeed = 0.7f;

	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;
	USickleCuttableHealthComponent EnemyHealthComp;
	UVineImpactComponent VineImpactComponent;
	UNiagaraComponent RushEffect;

	float Cooldown = 0;
	bool bTriggerDeactivation = false;
	FVector ChargeLocation;
	float CurrentMovementSpeed = 0;
	FVector LastPosition;

	TArray<AHazeCharacter> ImpactedActors;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
		EnemyHealthComp = AiOwner.SickleCuttableComp;
		VineImpactComponent = UVineImpactComponent::Get(AiOwner);
		Cooldown = CooldownTimeRange.Max;
		RushEffect = UNiagaraComponent::Get(AiOwner, n"RushEffect");
		//RushEffect.SetHiddenInGame(true);
		RushEffect.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsBlocked())
			Cooldown = FMath::Max(Cooldown - DeltaTime, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(Cooldown > 0)
			return EHazeNetworkActivation::DontActivate;

		if(!AiOwner.CanAttack())
			return EHazeNetworkActivation::DontActivate;

		AHazePlayerCharacter Target = AiOwner.GetCurrentTarget();
		if(Target == nullptr)
			return EHazeNetworkActivation::DontActivate;

		const float Distance = AiOwner.GetHorizontalDistanceToTarget(Target);
		if(Distance < AiComponent.ShieldDashAttackMinDistance)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(bTriggerDeactivation)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(ActiveDuration < ChargeDelay + ChargeTimeToReachMaxSpeed)
			return EHazeNetworkDeactivation::DontDeactivate;

		// We are stuck
		const float LastFrameMove = LastPosition.Dist2D(AiOwner.GetActorLocation());
		if(LastFrameMove < SMALL_NUMBER && GetActiveDuration() > 0.2f && CurrentMovementSpeed > 1)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		AHazePlayerCharacter Target = AiOwner.GetCurrentTarget();
		// This will change the controlside of the object
		AiOwner.LockPlayerAsTarget(Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		AHazePlayerCharacter Target = AiOwner.GetCurrentTarget();
		SetMutuallyExclusive(n"SickleEnemyAttack", true);

		AiOwner.BlockMovementWithInstigator(this);
		AiOwner.BlockAttackWithInstigator(this);
		AiOwner.bAttackingPlayer = true;
		AiOwner.LastAttackTime = Time::GetGameTimeSeconds();
		AiOwner.SetAnimBoolParam(n"Charge", true);
		bTriggerDeactivation = false;
		AiOwner.bHasMovementData = true;

		// We block the spawning while we are running
		AiComponent.BlockSpawning(this);
		
		ChargeLocation = Target.GetActorLocation();
		const FVector HorizontalDeltaToTarget = (ChargeLocation - AiOwner.GetActorLocation()).ConstrainToPlane(AiOwner.GetMovementWorldUp());
		ChargeLocation += HorizontalDeltaToTarget.GetSafeNormal() * FMath::RandRange(300.f, 1000.f); // We overshoot the target with 2 meters
		
		CurrentMovementSpeed = 0;
		LastPosition = AiOwner.GetActorLocation();

		if(VineImpactComponent != nullptr)
			VineImpactComponent.SetCanActivate(false, this);

		EnemyHealthComp.CustomBlockers.Add(this);

		//RushEffect.SetHiddenInGame(false);
		RushEffect.Activate(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiComponent.UnblockSpawning(this);
		SetMutuallyExclusive(n"SickleEnemyAttack", false);
		AiOwner.UnblockMovementWithInstigator(this);
		AiOwner.UnblockAttackWithInstigator(this);
		AiOwner.bAttackingPlayer = false;
		AiOwner.SetAnimBoolParam(n"Charge", false);
		AiOwner.UnblockTargetPicking();
		AiOwner.bHasMovementData = false;
		
		Cooldown = CooldownTimeRange.GetRandomValue();
	
		for(auto Other : ImpactedActors)
		{
			if(Other == nullptr)
				continue;
			
			auto OtherMovement = UHazeMovementComponent::Get(Other);
			OtherMovement.StopIgnoringActor(AiOwner);
			AiComponent.StopIgnoringActor(Other);

			auto PlayerOverlap = Cast<AHazePlayerCharacter>(Other);
			if(PlayerOverlap != nullptr)
			{
				PlayerOverlap.UnblockCapabilities(CapabilityTags::GameplayAction, this);
				PlayerOverlap.UnblockCapabilities(CapabilityTags::MovementAction, this);
				PlayerOverlap.UnblockCapabilities(CapabilityTags::MovementInput, this);
			}
		}
	
		ImpactedActors.Empty();

		if(VineImpactComponent != nullptr)
			VineImpactComponent.SetCanActivate(true, this);

		EnemyHealthComp.CustomBlockers.RemoveSwap(this);
		//RushEffect.SetHiddenInGame(true);
		RushEffect.Deactivate();
	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter Target = AiOwner.GetCurrentTarget();

		const FVector MyLocation = AiOwner.GetActorLocation();
		
		FVector HorizontalDeltaToTarget = (ChargeLocation - MyLocation).ConstrainToPlane(FVector::UpVector);

		if(CurrentMovementSpeed > 100)
		{
			TArray<AHazeCharacter> ToTraceAgainst;
			ToTraceAgainst.Add(Game::GetCody());
			ToTraceAgainst.Add(Game::GetMay());

			// We ignore the enemies for now.
			// for(ASickleEnemy Enemy : AiOwner.AreaToMoveIn.SickleEnemiesControlled)
			// {
			// 	if(Enemy == nullptr)
			// 		continue;
			// 	if(Enemy == AiOwner)
			// 		continue;

			// 	ToTraceAgainst.Add(Enemy);
			// }

			for(AHazeCharacter PossibleObsticles : ToTraceAgainst)
			{
				TryApplyImpactAgainstCharacter(PossibleObsticles);
			}	
		}

		if(AiComponent.ForwardHit.bBlockingHit || AiComponent.UpHit.bBlockingHit )
		{
			bTriggerDeactivation = true;
		}
		else if(AiOwner.RestrictedAreaToMoveIn != nullptr && AiOwner.RestrictedAreaToMoveIn.GetDistanceTo(AiOwner.GetActorLocation()) > 0)
		{
			bTriggerDeactivation = true;
		}
		else if(HorizontalDeltaToTarget.SizeSquared() > 1)
		{
			AiOwner.InitializeMovementForNextFrame();
			
			const float ActiveAlpha = FMath::Clamp((GetActiveDuration() - ChargeDelay) / ChargeTimeToReachMaxSpeed, 0.f, 1.f);
			CurrentMovementSpeed = FMath::Lerp(0.f, 5000.f, FMath::Pow(ActiveAlpha, 2.5f));

			AiComponent.SetTargetFacingDirection(HorizontalDeltaToTarget.GetSafeNormal());
			FVector MaxDelta = HorizontalDeltaToTarget.GetSafeNormal() * CurrentMovementSpeed * DeltaTime;
			const float MinSize = FMath::Min(MaxDelta.Size(), HorizontalDeltaToTarget.Size());
			AiOwner.TotalCollectedMovement.ApplyDelta(MaxDelta.GetSafeNormal() * MinSize);
		}
		else
		{
			bTriggerDeactivation = true;
		}

		LastPosition = MyLocation;
	}

	// TODO, Network
	void TryApplyImpactAgainstCharacter(AHazeCharacter Other)
	{
		if(!Other.HasControl())
			return;

		if(ImpactedActors.Contains(Other))
			return;

		const float SafetyAmount = 10.f;
		const float Distance = Other.GetHorizontalDistanceTo(AiOwner);
		const float MyHorizotalCollisionSize = AiOwner.GetCollisionSize().X;
		const float TargetHorizotalCollisionSize = Other.GetCollisionSize().X;

		const float ExtraImpactRadius = 300.f;
		const float TotalValidDistance = MyHorizotalCollisionSize + TargetHorizotalCollisionSize + ExtraImpactRadius;

		const FVector MyLocation = AiOwner.GetActorLocation();
	
		// Only collision inside the sphere
		if(Distance > TotalValidDistance)
			return;
	
		FVector HorizontalDirToPlayer = (Other.GetActorLocation() - MyLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		if(HorizontalDirToPlayer.IsNearlyZero())
			HorizontalDirToPlayer = AiOwner.GetActorForwardVector();

		// No collision behind
		if(HorizontalDirToPlayer.DotProduct(AiOwner.GetActorForwardVector()) < 0.25f)
			return;

		// No collision of the player is to high up
		FVector VerticalDeltaToPlayer = (Other.GetActorLocation() - MyLocation).ConstrainToDirection(FVector::UpVector);
		if(VerticalDeltaToPlayer.Size() > AiOwner.GetCollisionSize().Y * 1.5f)
			return;

		const float RightDot = HorizontalDirToPlayer.DotProduct(AiOwner.GetActorRightVector());
		float RightAmount = RightDot;
		if(FMath::Abs(RightAmount) > KINDA_SMALL_NUMBER)
			RightAmount = FMath::Sign(RightAmount);
		else if(FMath::RandBool())
			RightAmount = 1;
		else
			RightAmount = -1;


		FVector Force = FVector::ZeroVector;
		Force += AiOwner.GetActorForwardVector() * CurrentMovementSpeed * 0.25f * FMath::Abs(RightDot);
		Force += AiOwner.GetActorRightVector() * CurrentMovementSpeed * RightAmount * 0.4f;
		
		Force += FVector(0.f, 0.f, 1200.f);
	

		auto PlayerOverlap = Cast<AHazePlayerCharacter>(Other);
		if(PlayerOverlap != nullptr)
		{
			PlayerOverlap.MovementComponent.StopMovement();
			AddBurstForce(Other, Force, (-HorizontalDirToPlayer).Rotation());
			DamagePlayerHealth(PlayerOverlap, DamagePercentage, AiComponent.DamageEffect, AiComponent.DeathEffect);
			PlayerOverlap.BlockCapabilities(CapabilityTags::GameplayAction, this);
			PlayerOverlap.BlockCapabilities(CapabilityTags::MovementAction, this);
			PlayerOverlap.BlockCapabilities(CapabilityTags::MovementInput, this);
		}
		else
		{
			auto OtherAiOverlap = USickleEnemyComponentBase::Get(Other);
			auto OtherAiOwner = Cast<ASickleEnemy>(Other);
			FSickleEnemyHit Impact;
			Impact.KnockBackAmount = Force * 0.4f;
			Impact.KnockBackHorizontalMovementTime = 0.5f;
			Impact.KnockBackAmount.Z += 600.f; 
			Impact.StunnedDuration = 1.f;
			OtherAiOverlap.ApplyHit(Impact);
		}

		auto OtherMovement = UHazeMovementComponent::Get(Other);
		OtherMovement.StartIgnoringActor(AiOwner);
		AiComponent.StartIgnoringActor(Other);
		ImpactedActors.Add(Other);
	}
}