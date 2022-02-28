import Vino.Movement.Capabilities.KnockDown.CharacterKnockDownCapability;
import Cake.LevelSpecific.Tree.Beetle.Settings.BeetleSettings;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimFeature;
import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimationComponent;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetlePlayerDamageEffect;

enum EBeetleState
{
    None,
	Idle,
    Pursue,
	Telegraphing,
    Attack,
	Gore,
	Stomp,
	Pounce,
	MultiSlam,
	Recover,
	Stunned,

	MAX
}

FName GetBeetleStateTag(EBeetleState State)
{
	switch (State)
	{
		case EBeetleState::None: return NAME_None;
		case EBeetleState::Idle: return n"BeetleIdle";
		case EBeetleState::Pursue: return n"BeetlePursue";
		case EBeetleState::Telegraphing: return n"BeetleTelegraphing";
		case EBeetleState::Gore: return n"BeetleGore";
		case EBeetleState::Stomp: return n"BeetleStomp";
		case EBeetleState::Pounce: return n"BeetlePounce";
		case EBeetleState::Attack: return n"BeetleAttack";
		case EBeetleState::Recover: return n"BeetleRecover";
		case EBeetleState::Stunned: return n"BeetleStunned";
	}
	return NAME_None;
}

struct FBeetleSpecialAttackSlot
{
	EBeetleState SpecialAttackState = EBeetleState::Attack;
	int 		 NumChargesBeforeAttack = 0;
	float 		 MinRange = 0.f;
	float 		 MaxRange = BIG_NUMBER;	
}

event void FBeetleEvent();
event void FOnHitObstacle();

class UBeetleBehaviourComponent : UActorComponent
{
    AHazeCharacter CharOwner = nullptr;
	UBeetleSettings Settings = nullptr;

    // The behaviour state we will begin in
    UPROPERTY(Category = "BeetleBehaviour|State")
    EBeetleState CurrentState = EBeetleState::None;
    EBeetleState StateLastUpdate = EBeetleState::None;
    EBeetleState PreviousState = EBeetleState::None;
    float StateChangeTime = 0.f;
	float StunTime = 0.f;
	float GoreCompleteTime = BIG_NUMBER;
	int NumChargesSinceSpecialAttack = 0;
	TArray<FBeetleSpecialAttackSlot> SpecialAttackQueue;
	bool bHasPerformedSpecialAttack = false;

	AHazeActor CurrentTarget = nullptr;
	bool bKeepTarget = false;
	USceneComponent AttackHitDetectionCenter = nullptr;

	AHazeActor AggroTarget = nullptr;

	UPROPERTY(Category = "VOBark")
	UFoghornVOBankDataAssetBase VOBankDataAsset = Asset("/Game/Blueprints/LevelSpecific/Tree/VOBanks/WaspsNestVOBank.WaspsNestVOBank");

	UPROPERTY(meta = (NotBlueprintCallable))
	FBeetleEvent OnEntranceRoar();

	UPROPERTY(meta = (NotBlueprintCallable))
	FBeetleEvent OnEntranceDone();

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnHitObstacle OnHitObstacle;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBeetleEvent OnDefeat;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBeetleEvent OnHitTarget;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBeetleEvent OnStartAttack;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBeetleEvent OnStopAttack;

	UBeetleAnimFeature AnimFeature;
	UHazeCrumbComponent CrumbComp;
	UBeetleAnimationComponent AnimComp;

	TArray<AHazePlayerCharacter> FullbodyImpactTargets;

	UObject PendingController = nullptr;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		CharOwner = Cast<AHazeCharacter>(GetOwner());

		// Make sure players have some common capabilities
        UHazeAITeam Team = CharOwner.JoinTeam(n"BeetleTeam");
		Team.AddPlayersCapability(UCharacterKnockDownCapability::StaticClass());

		Settings = UBeetleSettings::GetSettings(CharOwner);

		AttackHitDetectionCenter = CharOwner.CapsuleComponent;

		CrumbComp = UHazeCrumbComponent::Get(Owner);
		AnimComp = UBeetleAnimationComponent::Get(Owner);
		AnimFeature = Cast<UBeetleAnimFeature>(CharOwner.Mesh.GetFeatureByClass(UBeetleAnimFeature::StaticClass()));

		ensure((CrumbComp != nullptr) && (AnimFeature != nullptr) && (AnimComp != nullptr));
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        CharOwner.LeaveTeam(n"BeetleTeam");
    }

    void InitializeStates()
    {
        UpdateState();
    }

	EBeetleState GetState() const property
	{
		return CurrentState;
	}

	void SetState(EBeetleState NewState) property
	{
		if (HasControl())
			CurrentState = NewState;
	}

	void LocalSetState(EBeetleState NewState)
	{
		CurrentState = NewState;
	}

    void UpdateState()
    {
        if (State != StateLastUpdate)
        {
            PreviousState = StateLastUpdate;
            StateLastUpdate = State;
            StateChangeTime = Time::GetGameTimeSeconds();
        }

		if (PendingController != nullptr)
		{
			if (HasControl())
			{
				LogEvent("Sending control change crumb");
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"Controller", PendingController);
				CharOwner.CleanupCurrentMovementTrailFromControl(FHazeCrumbDelegate(this, n"CrumbSetControlSide"), CrumbParams);
			}
			PendingController = nullptr;
		}
    }

    float GetStateDuration() property
    {
        return Time::GetGameTimeSince(StateChangeTime);
    }

    AHazeActor GetTarget() const property
    {
        return CurrentTarget;
    }

    void SetTarget(AHazeActor NewTarget) property
    {
        if (CurrentTarget == NewTarget)
            return;

		if (HasControl())
			PendingController = NewTarget;
        CurrentTarget = NewTarget;
    }

	AHazeActor GetBestTarget(AHazeActor SecondaryTarget)
	{
		bool bHasValidTarget = IsValidTarget(CurrentTarget);
		if (bKeepTarget && bHasValidTarget)
		{
			// Use same target again
			return CurrentTarget;
		}
		
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(CurrentTarget);
		if ((PlayerTarget != nullptr) && IsValidTarget(PlayerTarget.OtherPlayer))
		{
			// Alternate target for each attack, regardless whether we hit or not
			return PlayerTarget.OtherPlayer;
		}

		if (IsValidTarget(SecondaryTarget))
			return SecondaryTarget;

		// Keep previous target if possible
		if (bHasValidTarget)
			return Target;

		if (GetTargetScore(Game::GetCody()) > GetTargetScore(Game::GetMay()))
			return Game::GetCody();
		return Game::GetMay();
	}

	bool IsValidTarget(AHazeActor CheckTarget)
	{
		if (CheckTarget == nullptr)
			return false;
		if (CheckTarget.IsActorDisabled())
			return false;
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(CheckTarget);
		if ((PlayerTarget != nullptr) && IsPlayerDead(PlayerTarget))
			return false;
		return true;
	}

	bool HasValidTarget()
	{
		return IsValidTarget(Target);
	}

	float GetTargetScore(AHazeActor CheckTarget)
	{
		if (!IsValidTarget(CheckTarget))
			return -BIG_NUMBER;

		// Good target is near forward and close
		FVector ToTarget = CheckTarget.ActorLocation - CharOwner.ActorLocation;
		float DistSqr = ToTarget.SizeSquared();
		float Dot = CharOwner.ActorForwardVector.DotProduct(ToTarget);
		if (Dot > 0.f)
		{
			// When in front, score is dot of normalized vector to target and forward 
			// divided by distance, i.e. non-normalized dot / distsqr. 
			float Score = Dot / FMath::Max(1.f, DistSqr);
			return Score;
		}
		// When behind we get a negative score increasing with distance
		return -DistSqr;
	}

    bool CanHitTarget(AHazeActor CheckTarget, bool bFullBody = false)
    {
        if (!IsValidTarget(CheckTarget))
            return false;

		// We can only hit targets on their control side
		if (!CheckTarget.HasControl())	
			return false;

		FVector TargetLoc = CheckTarget.ActorLocation;
		if (bFullBody)
		{
			// Check if target is under/inside us
			FVector BodySlamLoc = Owner.ActorTransform.TransformPosition(Settings.StompOffset);
			//System::DrawDebugSphere(BodySlamLoc, Settings.StompRadius, 16, FLinearColor::Red);
			if (TargetLoc.IsNear(BodySlamLoc, Settings.StompRadius))
				return true;
		}

        // Project target location on our predicted movement to see if we'll be passing target soon.
        FVector ProjectedTargetLocation;
        float ProjectedFraction = 1.f;
        FVector HitCenter = AttackHitDetectionCenter.GetWorldTransform().TransformPosition(Settings.AttackCenterOffset);
        FVector MoveDelta = CharOwner.ActorVelocity * 0.1f;
		//System::DrawDebugSphere(HitCenter + MoveDelta, Settings.AttackHitRadius, 16, FLinearColor::Red);

        Math::ProjectPointOnLineSegment(HitCenter, HitCenter + MoveDelta, TargetLoc, ProjectedTargetLocation, ProjectedFraction);
        if (ProjectedTargetLocation.DistSquared(TargetLoc) > FMath::Square(Settings.AttackHitRadius))
            return false; // Passing target, but too far away

        // Close enough to hit target!
        return true;
    }

	UFUNCTION(NotBlueprintCallable)
	void CrumbSetControlSide(const FHazeDelegateCrumbData& CrumbParams)
	{
		// Switch to target control side. Previous control side will have to wait in current state 
	 	// until remote side catches up, sets itself as control and start dropping crumbs
		UObject Controller = CrumbParams.GetObject(n"Controller");
	 	CharOwner.SetControlSide(Controller);
		LogEvent("Receiving control change crumb, new controller is " + Controller.Name);
	}

	UFUNCTION()
	void StartEntrance()
	{
		// Full sync so we don't start behaviour until both sides are done with cutscene
		Sync::FullSyncPoint(this, n"EntranceSynced");
	}

	UFUNCTION(NotBlueprintCallable)
	void EntranceSynced()
	{
		State = EBeetleState::Idle;
	}

	UFUNCTION()
	void Stun(float Duration)
	{
		State = EBeetleState::Stunned;
		StunTime = Time::GetGameTimeSeconds() + Duration;
	}

	UFUNCTION()
	void OnTakeDamage(float RemainingHealth, AHazePlayerCharacter Attacker, float BatchDamage, const FVector& DamageDir)
	{
		LogEvent("Beetle taking " + FMath::RoundToInt(BatchDamage) + " damage , remaining health is " + RemainingHealth);

		if (Settings.bUseSpecialAttackWhenDamaged && (SpecialAttackQueue.Num() > 0))
			NumChargesSinceSpecialAttack = SpecialAttackQueue[0].NumChargesBeforeAttack;

		if ((RemainingHealth > 0) && (BatchDamage < Settings.StunMinDamage))
		{
			// Just a flesh wound!
			AnimComp.PlayAdditiveHurt(DamageDir);
			return;
		}

		// This is triggered through crumb from attacker control side (so could be control or remote side for us)
		if (RemainingHealth > 0)
			Stun(Settings.DamageStunDuration);
		else
			SetState(EBeetleState::None); // Brain dead!

		if (!HasControl() && Attacker.HasControl())
		{
			// On remote side detecting an attack. Control side will be notified, 
			// but until it tells us we can become the new control side let's fake 
			// getting hurt and stop other animations from playing.
			AnimComp.PlayStartMH(AnimFeature.Stunned_Start, AnimFeature.Stunned_MH);
			AnimComp.BlockNewAnims();
		}
	}

	UFUNCTION()
	void OnGoreComplete()
	{
		GoreCompleteTime = Time::GetGameTimeSeconds();	
	}

	UFUNCTION()
	void UpdateSpecialAttackQueue()
	{
		for(FBeetleSpecialAttackSlot& Slot : SpecialAttackQueue)
		{
			switch (Slot.SpecialAttackState)
			{
				case EBeetleState::Pounce:
					Slot.NumChargesBeforeAttack = Settings.PounceInterval;
					continue;
				case EBeetleState::MultiSlam:
					Slot.NumChargesBeforeAttack = Settings.MultiSlamInterval;
					continue;
			}
		}
	}

	UFUNCTION()
	void QueueSpecialAttack(EBeetleState SpecialAttack, int NumChargesBeforeAttack, float MinRange, float MaxRange)
	{
		FBeetleSpecialAttackSlot Slot;
		Slot.SpecialAttackState = SpecialAttack;
		Slot.NumChargesBeforeAttack = NumChargesBeforeAttack;
		Slot.MinRange = MinRange;
		Slot.MaxRange = MaxRange;
		SpecialAttackQueue.Add(Slot);
	}

	EBeetleState SelectNextAttackState()
	{
		// Take first valid special attack
		for (int i = 0; i < SpecialAttackQueue.Num(); i++)
		{
			// We must have done enough charges to trigger a special attack to consider any later special attacks
			if (NumChargesSinceSpecialAttack < SpecialAttackQueue[i].NumChargesBeforeAttack)
				break; // No special attack for you!
			
			// Take first special attack within range
			if (Owner.ActorLocation.IsNear(Target.ActorLocation, SpecialAttackQueue[i].MinRange))
				continue; // Within min range, try next

			if (!Owner.ActorLocation.IsNear(Target.ActorLocation, SpecialAttackQueue[i].MaxRange))
				continue; // Outside max range, try next
			
			// Attack passed muster, use it!
			return SpecialAttackQueue[i].SpecialAttackState;
		}
		// Normal charge
		return EBeetleState::Attack;
	}	

	void UseAttackState(EBeetleState AttackState)
	{
		if (AttackState == EBeetleState::Attack)
		{
			// Normal charge
			NumChargesSinceSpecialAttack++;
			return;
		}

		// Special attack
		NumChargesSinceSpecialAttack = 0;
		bHasPerformedSpecialAttack = true;
		
		// Remove from queue
		for (int i = 0; i < SpecialAttackQueue.Num(); i++)
		{
			if (SpecialAttackQueue[i].SpecialAttackState == AttackState)
			{
				SpecialAttackQueue.RemoveAt(i);
				break;
			}
		}
	}	

	void ResetFullBodyImpact()
	{
		FullbodyImpactTargets = Game::GetPlayers();
	}

	void CheckFullbodyImpact()
	{
		for (int i = FullbodyImpactTargets.Num() - 1; i >= 0; i--)
		{
			if (CanHitTarget(FullbodyImpactTargets[i], true))
				FullbodyImpact(FullbodyImpactTargets[i]);	
		}
	}

	void FullbodyImpact(AHazePlayerCharacter ImpactTarget)
	{
		// ImpactTarget can only be hit on it's own control side
		if (!ImpactTarget.HasControl())
			return;

		FullbodyImpactTargets.Remove(ImpactTarget);

		// Always use target crumb component since we won't actually interrupt own action, but will affect target.
		UHazeCrumbComponent HitCrumbComp = UHazeCrumbComponent::Get(ImpactTarget);			
		if (!ensure(HitCrumbComp != nullptr))
			return;
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Target", ImpactTarget);
		CrumbParams.AddVector(n"Force", GetFullBodyImpactForce(ImpactTarget));
		HitCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbFullbodyImpact"), CrumbParams);
	}

	FVector GetFullBodyImpactForce(AHazePlayerCharacter ImpactTarget)
	{
		FVector Direction = (ImpactTarget.ActorLocation - Owner.ActorLocation);
		Direction.Z = FMath::Max(500.f, Direction.Z);
		return Direction.GetSafeNormal() * Settings.AttackForce;
	}

	UFUNCTION()
	void CrumbFullbodyImpact(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter ImpactTarget = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Target"));
		if (ImpactTarget == nullptr)
			return;

		ImpactTarget.SetCapabilityAttributeVector(n"KnockdownDirection", CrumbData.GetVector(n"Force"));
		ImpactTarget.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);

        // Do damage
		DamagePlayerHealth(ImpactTarget, 1.0f, TSubclassOf<UPlayerDamageEffect>(UBeetlePlayerDamageEffect::StaticClass()));
	}

	void LogEvent(FString Desc, FString Postfix = "")
	{
#if TEST
		FString PlayerSide = (Game::May != nullptr) ? (Game::May.HasControl() ? "(May side)" : "(Cody side)") : "(No players yet)";
		FName TargetName = (Target != nullptr) ? Target.GetName() : n"None";
		Log(PlayerSide + " Beetle " + 
			(HasControl() ? "CONTROL" : "REMOTE") + " " +
			Desc + ", target is " + TargetName + " " + 
			Postfix);
#endif
	}
}