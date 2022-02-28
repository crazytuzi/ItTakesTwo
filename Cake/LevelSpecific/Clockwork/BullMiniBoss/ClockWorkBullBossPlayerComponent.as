import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;

void SetupBullBossForPlayer(AClockworkBullBoss Boss)
{
	TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
	for(auto Player : Players)
	{
		UClockWorkBullBossPlayerComponent::Get(Player).BullBoss = Boss;
		Boss.MovementComponent.StartIgnoringActor(Player);
	}
}

// void ReleaseAttachedPlayers(AClockworkBullBoss Boss)
// {
// 	TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
// 	for(auto Player : Players)
// 	{
// 		auto BullComp = UClockWorkBullBossPlayerComponent::Get(Player);
// 		if(!BullComp.bIsAttachedToBoss)
// 			continue;
// 	}

// 	Boss.AttachedPlayers.Empty();
// }

void TriggerImpactOnPlayer(FBullValidImpactData Impact, AHazePlayerCharacter Player)
{
	auto BullComp = UClockWorkBullBossPlayerComponent::Get(Player);

	if(BullComp.bIsTakingDamageFromBoss)
		return;

	// Need to wait for this type of attack to trigger again
	if(BullComp.SameAttackCooldown > 0)
	{
		if(Impact.DamageType == BullComp.LastActiveDamage.DamageType)
			return;

		if(Impact.DamageInstigator == BullComp.LastActiveDamage.DamageInstigator)
			return;
	}

	BullComp.NetSetupImpact(Impact, BullComp.BullBoss.ActorRotation);
}

class UClockWorkBullBossPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	ULocomotionFeatureTakeBullBossDamage TakeDamageFeaure;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MoveComp;
	AClockworkBullBoss BullBoss;

	bool bIsTakingDamageFromBoss = false;

	bool bIsAttachedToBoss = false;
	bool bShouldBeAttachedToBoss = false;
	EBullBossDamageInstigatorType RequiredAttachmentInstigator = EBullBossDamageInstigatorType::None;
	float TimeLeftToRelease = 0;
	
	FBullValidImpactData ActiveDamage;
	FBullValidImpactData LastActiveDamage;

	float LockedIntoTakeDamageTime = 0;
	float SameAttackCooldown = 0;

	TArray<UObject> IgnoreInMovementInstigators;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsTakingDamageFromBoss)
		{
			LockedIntoTakeDamageTime = FMath::Max(LockedIntoTakeDamageTime - DeltaSeconds, 0.f);
		}
		else
		{
			SameAttackCooldown = FMath::Max(SameAttackCooldown - DeltaSeconds, 0.f);
		}

		if(TimeLeftToRelease > 0)
		{
			TimeLeftToRelease -= DeltaSeconds;
			if(TimeLeftToRelease <= 0)
			{
				TimeLeftToRelease = 0;
				bShouldBeAttachedToBoss = false;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetupImpact(FBullValidImpactData Data, FRotator ImpactOrientation)
	{
		LastActiveDamage = ActiveDamage;
		ActiveDamage = Data;
		ActiveDamage.DamageForce = ImpactOrientation.RotateVector(ActiveDamage.DamageForce);
		LockedIntoTakeDamageTime = ActiveDamage.LockedIntoTakeDamageTime;
		SameAttackCooldown = BullBoss.Settings.SameImpactCooldown;
		bIsTakingDamageFromBoss = true;
	}

	
	void ClearImpact()
	{
		bIsTakingDamageFromBoss = false;
		LockedIntoTakeDamageTime = 0;
	}

	void AttachToBull(EBullBossDamageInstigatorType AttachType)
	{
		if(!HasControl())
			return;

		if(AttachType == EBullBossDamageInstigatorType::None)
			return;

		if(bIsAttachedToBoss)
			return;
		
		bIsAttachedToBoss = true;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddNumber(n"AttachInstigator", int(AttachType));
		UHazeCrumbComponent::Get(PlayerOwner).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_AttachToBull"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_AttachToBull(const FHazeDelegateCrumbData& CrumbData)
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);	

		const FBullAttackCollisionData& collision = BullBoss.CollisionData[CrumbData.GetNumber(n"AttachInstigator")];
		PlayerOwner.TriggerMovementTransition(this, n"AttachToBull");
		PlayerOwner.BlockMovementSyncronization(this);
		PlayerOwner.AttachToComponent(BullBoss.RootComponent);
		PlayerOwner.MeshOffsetComponent.AttachToComponent(BullBoss.Mesh, collision.CollisionComponent.AttachBoneName);
		
		PlayerOwner.SetAnimBoolParam(n"IsAttachedToBull", true);
	}

	void DetachFromBull()
	{
		if(!HasControl())
			return;

		if(!bIsAttachedToBoss)
			return;

		// Test the best position to snap the actor to.
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(MoveComp);
		TraceParams.IgnoreActor(BullBoss);
		TraceParams.From = PlayerOwner.ActorLocation;
		TraceParams.To = PlayerOwner.MeshOffsetComponent.GetWorldLocation();

		FVector LocationToSet;
		FHazeHitResult Hit;
		if(TraceParams.Trace(Hit))
			LocationToSet = Hit.ActorLocation;
		else
			LocationToSet = TraceParams.To;	

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddVector(n"ActorLocation", LocationToSet);
		UHazeCrumbComponent::Get(PlayerOwner).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_DetachFromBull"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_DetachFromBull(const FHazeDelegateCrumbData& CrumbData)
	{
		PlayerOwner.TriggerMovementTransition(this, n"DetachFromBull");

		bIsAttachedToBoss = false;
		PlayerOwner.MeshOffsetComponent.FreezeAndResetWithTime(0.25f);
		PlayerOwner.MeshOffsetComponent.AttachToComponent(PlayerOwner.RootOffsetComponent, NAME_None, EAttachmentRule::KeepWorld);
		PlayerOwner.DetachRootComponentFromParent();

		PlayerOwner.SetAnimBoolParam(n"IsAttachedToBull", false);

		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);

		PlayerOwner.UnblockMovementSyncronization(this);
		
		PlayerOwner.SetActorLocation(CrumbData.GetVector(n"ActorLocation"));
	}

	void IgnoreBullBossInMovement(UObject Instigator, bool bStatus)
	{
		if(Instigator == nullptr)
			return;
		
		if(bStatus)
		{
			IgnoreInMovementInstigators.AddUnique(Instigator);
			if(IgnoreInMovementInstigators.Num() == 1)
				UHazeMovementComponent::Get(PlayerOwner).StartIgnoringActor(BullBoss);
		}
		else
		{
			IgnoreInMovementInstigators.RemoveSwap(Instigator);
			if(IgnoreInMovementInstigators.Num() == 0)
				UHazeMovementComponent::Get(PlayerOwner).StopIgnoringActor(BullBoss);
		}
	}
}