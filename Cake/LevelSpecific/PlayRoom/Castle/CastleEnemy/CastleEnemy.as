import Vino.Characters.AICharacter;
import Vino.PlayerHealth.PlayerHealthStatics;

event void FOnCastleEnemyTakeDamage(ACastleEnemy Enemy, FCastleEnemyDamageEvent Event);
event void FOnCastleEnemyKilled(ACastleEnemy Enemy, bool bKilledByDamage);
event void FOnCastleEnemyKnockedBack(ACastleEnemy Enemy, FCastleEnemyKnockbackEvent Event);
event void FOnCastleEnemyAggroed(ACastleEnemy Enemy, AHazePlayerCharacter Player, FCastleEnemyAggroFlags AggroFlags);
event void FOnCastleEnemyHealthChanged(ACastleEnemy Enemy);

import void RegisterEnemy(ACastleEnemy) from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList";
import void UnregisterEnemy(ACastleEnemy) from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList";
import const TArray<ACastleEnemy>& GetAllCastleEnemies() from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList";
import bool IsPlayerHiddenFromEnemies(AHazePlayerCharacter) from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent";

const float LINE_OF_SIGHT_RECALC_INTERVAL = 1.f;

enum ECastleEnemyDamageType
{
    Generic,
	Burn,
	Mirror,
};

struct FCastleEnemyDamageEvent
{
    UPROPERTY()
    AHazeActor DamageSource;
    UPROPERTY()
    ECastleEnemyDamageType DamageType = ECastleEnemyDamageType::Generic;
    UPROPERTY()
    int DamageDealt = 0;
    UPROPERTY()
    FVector DamageLocation;
    UPROPERTY()
    FVector DamageDirection;
	UPROPERTY()
	float DamageSpeed = 300.f;
    UPROPERTY()
    bool bIsCritical = false;

    bool HasDirection() const
    {
        return !DamageDirection.IsNearlyZero();
    }
};

struct FCastleEnemyKnockbackEvent
{
    UPROPERTY()
    AHazeActor Source;
    UPROPERTY()
    FVector Location;
    UPROPERTY()
    FVector Direction;
    UPROPERTY()
    float HorizontalForce = 1.f;
    UPROPERTY()
    float VerticalForce = 1.f;
    UPROPERTY()
    float DurationMultiplier = 1.f;
    UPROPERTY()
    UCurveFloat KnockBackCurveOverride = nullptr;
    UPROPERTY()
    UCurveFloat KnockUpCurveOverride = nullptr;
	UPROPERTY()
	FName KnockbackTag = NAME_None;
};

struct FCastleEnemyAggroFlags
{
    UPROPERTY()
    bool bFromGroupAggro = false;
    UPROPERTY()
    bool bAutomaticAggro = false;
};

enum ECastleEnemyStatusType
{
	Freeze,
	Burn,

	MAX
};

struct FCastleEnemyStatusEffect
{
	UPROPERTY()
	ECastleEnemyStatusType Type;

	UPROPERTY()
	float Duration = 1.f;

	UPROPERTY()
	float Magnitude = 1.f;
};

struct FCastleEnemyStatusStacks
{
	int StackCount = 0;
	float TotalMagnitude = 0.f;
	float RemainingDuration = 0.f;
};

enum ECastleEnemyMusicIntensityType
{
	None, 			// Enemy will not affect music intensity.
	Default, 		// Enemy will trigger combat intensity when they want to fight.
	AlwaysCombat,	// Enemy will trigger combat intensity when they spawn.
}

UCLASS(Abstract)
class ACastleEnemy : AHazeCharacter
{ 
	default CapsuleComponent.SetCollisionProfileName(n"Enemy");
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
	default CapsuleComponent.bGenerateOverlapEvents = false;

	default Mesh.bReceiveWorldShadows = false;
	default Mesh.bComponentUseFixedSkelBounds = true;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent AIMovementComponent;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 3500.f;

    UPROPERTY(Category = "Health")
    int MaxHealth = 100;

    UPROPERTY(BlueprintReadOnly, NotEditable, Category = "Health")
    int Health = 0;

    UPROPERTY(Category = "Health")
	bool bShowHealthBar = true;

	// Whether the healthbar for this enemy should be visible at all times
    UPROPERTY(Category = "Health")
	bool bAlwaysShowHealthBar = false;

	UPROPERTY(Category = "Health")
    bool bShowHeathBarWhenEnemyNotRendered = false;

	UPROPERTY(Category = "Health")
    bool bSmallHealthBar = true;

	// Offset of the healthbar above the enemy in screen space
    UPROPERTY(Category = "Health")
	int HealthBarScreenspaceOffset = 50;

    UPROPERTY(Category = "Health")
	bool bUnhittable = false;

    UPROPERTY(Category = "Health")
	bool bInvulnerable = false;

    UPROPERTY(Category = "Health")
	bool bCanDie = true;

	// Whether to change the network side of the enemy when its aggro changes
    UPROPERTY(BlueprintReadOnly)
	bool bChangeNetworkSideOnAggro = true;

    // If a player gets within this distance, aggro it
	UPROPERTY(Category = "Aggro")
	float EnemyAggroRange = 1400.f;

    /* If the player we're aggroed on moves this far away, de-aggro
       -1 means never de-aggro. */
	UPROPERTY(Category = "Aggro")
	float EnemyLoseAggroRange = -1.f;

    // Enemies within this radius from an aggroed enemy will also aggro the same target
	UPROPERTY(Category = "Aggro")
	float AllyGroupAggroRange = 600.f;

    // Whether we can aggro through player conditional objects
	UPROPERTY(Category = "Aggro")
	bool bPlayerConditionalBlocksLOS = true;

	// Going further away than this range from its starting position will
	// make the enemy turn back
	UPROPERTY(Category = "Aggro")
	float LeashRange = 0.f;

	// When no aggro is held for this amount of time, return to leash position
	UPROPERTY(Category = "Aggro")
	float LeashReturnTimer = 0.f;

	// Chase capability will refuse to move further away than this from leash, but will keep aggro
	UPROPERTY(Category = "Aggro", AdvancedDisplay)
	float LeashMaxMovement = 0.f;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapability;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    FCastleEnemyDamageEvent PreviousDamageEvent;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    TArray<FCastleEnemyDamageEvent> FrameDamageEvents;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bTookDamageThisFrame = false;

    UPROPERTY(NotEditable)
    bool bDelayDeath = false;

    // An enemy has been 'killed' as soon as it has taken fatal damage and will die
    UPROPERTY(NotEditable, BlueprintReadOnly)
    bool bKilled = false;

    // An enemy is only 'dead' once its death animation finishes and it's fully gone
    UPROPERTY(NotEditable, BlueprintReadOnly)
    bool bDead = false;

    // The player that this enemy is currently aggroed on
    UPROPERTY(NotEditable, BlueprintReadOnly)
    AHazePlayerCharacter AggroedPlayer;

    // Current aggro flags for the player we've aggroed
    UPROPERTY(NotEditable, BlueprintReadOnly)
    FCastleEnemyAggroFlags CurrentAggroFlags;

    // The enemy's base movement speed
    UPROPERTY(Category = "Movement")
    float MovementSpeed = 500.f;

    // The enemy's base facing rotation speed
    UPROPERTY(Category = "Movement")
    float FacingRotationSpeed = 4.f;

	// Whether to use the minimal collision solver or not
    UPROPERTY(Category = "Movement")
	bool bUseMinimalCollisionSolver = true;

	// Current action speed for the enemy that it can move/attack at
	float ActionSpeed = 1.f;

	// Curve mapping freeze magnitude to movement speed muliplier
    UPROPERTY()
	UCurveFloat FrozenMovementSpeedCurve;

	// How much damage per second this enemy takes if it is burning
    UPROPERTY()
	float BurningDPS = 5.f;

	// Multiplier for ultimate charge gained by hitting this enemy
	UPROPERTY()
	float HitUltimateChargeMultiplier = 1.f;

    UPROPERTY(Category = "Aggro")
	bool bCanAggro = true;

	UPROPERTY(Category = "FX")
	UNiagaraSystem EnemyDeathEffect;

    UPROPERTY()
    FOnCastleEnemyTakeDamage OnTakeDamage;

    UPROPERTY()
    FOnCastleEnemyKilled OnKilled;

    UPROPERTY()
    FOnCastleEnemyKnockedBack OnKnockedBack;

    UPROPERTY()
    FOnCastleEnemyAggroed OnAggroed;

    UPROPERTY()
    FOnCastleEnemyHealthChanged OnHealthChanged;

	TPerPlayer<FLineOfSightData> LineOfSightData;

	UPROPERTY()
	bool bTempBoolAllowFalling = true;

	default Mesh.SetCullDistance(10000);

	default AIMovementComponent.ControlSideDefaultCollisionSolver = n"MinimalAICharacterSolver";
	default AIMovementComponent.RemoteSideDefaultCollisionSolver = n"RemoteMinimalAICharacterSolver";
	default AIMovementComponent.ControlSideDefaultMoveWithCollisionSolver = n"MinimalAICharacterSolver";
	default AIMovementComponent.RemoteSideDefaultMoveWithCollisionSolver = n"RemoteMinimalAICharacterSolver";

	default PrimaryActorTick.bStartWithTickEnabled = false;

	FVector LeashFromPosition;
	FRotator LeashPositionRotation;

	TArray<FCastleEnemyStatusStacks> StatusStacks;
	bool bLocalDeath = false;
	FVector KillDirection;
	int AutoDisableBlocks = 0;

	UPROPERTY()
	ECastleEnemyMusicIntensityType MusicIntensityType = ECastleEnemyMusicIntensityType::Default;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		AIMovementComponent.Setup(CapsuleComponent);

		if (!bUseMinimalCollisionSolver)
		{
			AIMovementComponent.UseCollisionSolver(n"AICharacterSolver", n"AICharacterRemoteCollisionSolver");
			AIMovementComponent.UseMoveWithCollisionSolver(n"AICharacterSolver", n"AICharacterRemoteCollisionSolver");
		}

        Health = MaxHealth;
		AddDefaultCapabilities();

		RegisterEnemy(this);
		UpdateLeashPosition();
    }

	void AddDefaultCapabilities()
	{
		if (Network::IsNetworked() && Game::IsEditorBuild())
			AddDebugCapability(n"AISkeletalMeshNetworkVisualizationCapability");

        AddCapability(n"CastleEnemyHealthCapability");
        AddCapability(n"CastleEnemyMovementCapability");
        AddCapability(n"CastleEnemyAISpawnLoiterCapability");
        AddCapability(n"CastleEnemyAIForcedMoveToCapability");
		if (bTempBoolAllowFalling)
        	AddCapability(n"CastleEnemyFallingCapability");
        AddCapability(n"CastleEnemyKnockbackFinalizeCapability");
        AddCapability(n"CastleEnemyIdleAnimationCapability");
		if (BurningDPS > 0.f)
			AddCapability(n"CastleEnemyBurnCapability");
		if (bChangeNetworkSideOnAggro)
			AddCapability(n"CastleEnemyControlledBySideCapability");
		if (LeashRange > 0.f || LeashReturnTimer > 0.f)
			AddCapability(n"CastleEnemyAILeashReturnCapability");
		if (MusicIntensityType == ECastleEnemyMusicIntensityType::Default)
			AddCapability(n"CastleEnemyMusicIntensityCapability");
		if (MusicIntensityType == ECastleEnemyMusicIntensityType::AlwaysCombat)
			AddCapability(n"CastleEnemyAlwaysCombatMusicIntensityCapability");

		UClass AudioClass = AudioCapability.Get();
		if(AudioClass != nullptr)
			AddCapability(AudioClass);		
	}

	void UpdateLeashPosition()
	{
		LeashFromPosition = ActorLocation;
		LeashPositionRotation = ActorRotation;
	}

	void SetLeashPosition(FVector Location, FRotator Rotation)
	{
		LeashFromPosition = Location;
		LeashPositionRotation = Rotation;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		UnregisterEnemy(this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		UnregisterEnemy(this);
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		RegisterEnemy(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bNeedUpdate = false;

		if (UpdateStatusEffects(DeltaTime))
			bNeedUpdate = true;

		if (!bNeedUpdate)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintPure)
	float GetMovementMultiplier() property
	{
		if (FrozenMovementSpeedCurve == nullptr)
			return 1.f;
		float Magnitude = GetStatusMagnitude(ECastleEnemyStatusType::Freeze);
		return FrozenMovementSpeedCurve.GetFloatValue(Magnitude);
	}

	UFUNCTION(BlueprintPure)
	float GetStatusMagnitude(ECastleEnemyStatusType StatusType)
	{
		if (int(StatusType) >= StatusStacks.Num())
			return 0.f;
		return StatusStacks[int(StatusType)].TotalMagnitude;
	}

	UFUNCTION()
	void ApplyStatusEffect(FCastleEnemyStatusEffect StatusEffect)
	{
		if (HasControl())
			NetApplyStatusEffect(StatusEffect);
	}

	UFUNCTION(NetFunction)
	private void NetApplyStatusEffect(FCastleEnemyStatusEffect StatusEffect)
	{
		if (int(StatusEffect.Type) >= StatusStacks.Num())
			StatusStacks.SetNum(int(StatusEffect.Type) + 1);

		FCastleEnemyStatusStacks& Stacks = StatusStacks[int(StatusEffect.Type)];
		Stacks.StackCount += 1;
		Stacks.TotalMagnitude += StatusEffect.Magnitude;
		Stacks.RemainingDuration = FMath::Max(Stacks.RemainingDuration, StatusEffect.Duration);
		SetActorTickEnabled(true);
	}

	UFUNCTION(NetFunction)
	private void NetResetStatusEffect(ECastleEnemyStatusType Type)
	{
		FCastleEnemyStatusStacks& Stacks = StatusStacks[int(Type)];
		Stacks.RemainingDuration = 0.f;
		Stacks.StackCount = 0;
		Stacks.TotalMagnitude = 0.f;
	}

	bool UpdateStatusEffects(float DeltaTime)
	{
		bool bHasStatus = false;
		for (int i = 0, Count = StatusStacks.Num(); i < Count; ++i)
		{
			FCastleEnemyStatusStacks& Stacks = StatusStacks[i];
			if (Stacks.StackCount <= 0)
				continue;

			Stacks.RemainingDuration -= DeltaTime;
			if (Stacks.RemainingDuration <= 0.f)
			{
				if (HasControl())
					NetResetStatusEffect(ECastleEnemyStatusType(i));
			}
			else
			{
				bHasStatus = true;
			}
		}

		return bHasStatus;
	}

	UFUNCTION()
    void Kill(bool bKilledByDamage = false, FVector OverrideKillDirection = FVector::ZeroVector)
    {
		if (HasControl())
		{
			if (!bKilled)
			{
				//Log(""+this+" - Control: "+HasControl()+" - Kill");
				FHazeDelegateCrumbParams Params;
				if (bKilledByDamage)
					Params.AddActionState(n"KilledByDamage");
				Params.AddVector(n"OverrideKillDirection", OverrideKillDirection);
				CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Kill"), Params);
			}
		}
		else
		{
			bLocalDeath = true;
		}
    }

	UFUNCTION()
	private void Crumb_Kill(FHazeDelegateCrumbData Params)
	{
		//Log(""+this+" - Control: "+HasControl()+" - Crumb_Kill");
		KillInternal(
			Params.GetActionState(n"KilledByDamage"),
			Params.GetVector(n"OverrideKillDirection")
		);
		TriggerMovementTransition(this, n"Kill");
	}

	void KillInternal(bool bKilledByDamage, FVector OverrideKillDirection)
	{
        if (bKilled)
            return;
        bKilled = true;
		KillDirection = OverrideKillDirection;
        OnKilled.Broadcast(this, bKilledByDamage);
		UnregisterEnemy(this);
        if (!bDelayDeath)
            FinalizeDeath();
	}

    void FinalizeDeath()
    {
        if (bDead)
            return;
        bDead = true;

		// We don't actually destroy the actor until after 10s,
		// that way all the net messages will happen properly.
		bUnhittable = true;
		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);
		System::SetTimer(this, n"FinalDestroy", 10.f, false);
    }

	UFUNCTION()
	private void FinalDestroy()
	{
        DestroyActor();
	}

    UFUNCTION()
    bool TakeDamage(FCastleEnemyDamageEvent Event)
    {
		if (!Event.DamageSource.HasControl())
			return false;
		if (bKilled)
			return false;
		if (bUnhittable)
			return false;

        PreviousDamageEvent = Event;
		if (bInvulnerable)
			PreviousDamageEvent.DamageDealt = 0;

        // If no specific damage direction was passed, calculate an approximation
        PreviousDamageEvent.DamageDirection = ComputeDamageDirection(PreviousDamageEvent.DamageDirection, Event.DamageLocation);
		NetTakeDamage(PreviousDamageEvent);

		return true;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetTakeDamage(FCastleEnemyDamageEvent Event)
	{
        PreviousDamageEvent = Event;

        FrameDamageEvents.Add(PreviousDamageEvent);
        bTookDamageThisFrame = true;

        // Reduce health
        Health -= PreviousDamageEvent.DamageDealt;
		OnHealthChanged.Broadcast(this);

        // Inform anything that wants to respond
        OnTakeDamage.Broadcast(this, PreviousDamageEvent);

        // Kill the enemy if its health is zero
        if (Health <= 0 && bCanDie)
			Kill();
    }

	void OnReceivedControl()
	{
		if (bLocalDeath)
			Kill();
	}

	UFUNCTION()
	void SetEnemyHealth(float NewHealth)
	{		
		if (HasControl())
			NetModifyEnemyHealth(int(NewHealth) - Health);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetModifyEnemyHealth(int Delta)
	{
		Health += Delta;
		OnHealthChanged.Broadcast(this);
	}

    // Overridable function that changes depending on how the actor responds to flashes
    UFUNCTION(BlueprintEvent)
    void SetDamageFlash(float FlashAmount)
    {
    }

    UFUNCTION()
    void KnockBack(FCastleEnemyKnockbackEvent Event)
    {
		// Unable to be knocked back if unhittable
		if (bUnhittable)
			return;
		if (bKilled)
			return;

		if (!Event.Source.HasControl())
			return;

        FCastleEnemyKnockbackEvent FinalEvent;
        FinalEvent = Event;
        FinalEvent.Direction = ComputeDamageDirection(FinalEvent.Direction, FinalEvent.Location);
		NetKnockBack(FinalEvent);
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetKnockBack(FCastleEnemyKnockbackEvent Event)
	{
        OnKnockedBack.Broadcast(this, Event);
    }

    // Calculate an approximate damage direction for a damage source
    FVector ComputeDamageDirection(FVector InDirection, FVector Location)
    {
        FVector Direction = InDirection;
        // Always constrain damage direction to the horizontal plane
        if (Direction.IsNearlyZero())
            Direction = (ActorLocation - Location).GetSafeNormal();
        if (!Direction.IsNearlyZero())
            Direction = Math::ConstrainVectorToPlane(Direction, FVector::UpVector).GetSafeNormal();
        return Direction;
    }

    // Force the enemy to aggro on a specific player right now
    UFUNCTION()
    void AggroPlayer(AHazePlayerCharacter Player, FCastleEnemyAggroFlags AggroFlags)
    {
		if (HasControl())
		{
			if (AggroedPlayer != Player && bCanAggro)
				NetAggroPlayer(Player, AggroFlags);
		}
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetAggroPlayer(AHazePlayerCharacter Player, FCastleEnemyAggroFlags AggroFlags)
	{
        AggroedPlayer = Player;
		if (Player != nullptr)
		{
			CurrentAggroFlags = AggroFlags;
			OnAggroed.Broadcast(this, Player, AggroFlags);
		}
	}

    // Force the enemy to clear its current aggro and retarget
    UFUNCTION()
    void ClearAggro()
    {
		if (HasControl())
			NetAggroPlayer(nullptr, FCastleEnemyAggroFlags());
    }

    // Group aggro all enemies within a certain distance of this enemy
    UFUNCTION()
    void GroupAggroNearbyEnemies(float GroupAggroRange, AHazePlayerCharacter Player, FCastleEnemyAggroFlags AggroFlags)
    {
        FCastleEnemyAggroFlags SubFlags;
        SubFlags = AggroFlags;
        SubFlags.bFromGroupAggro = true;

        const TArray<ACastleEnemy>& AllEnemies = GetAllCastleEnemies();

        FVector MyLocation = ActorLocation;
        float AggroDistSQ = FMath::Square(GroupAggroRange);

        for(auto OtherEnemy : AllEnemies)
        {
            if (OtherEnemy == this)
                continue;
            float DistSQ = OtherEnemy.ActorLocation.DistSquared(MyLocation);
            if (DistSQ < AggroDistSQ)
                OtherEnemy.AggroPlayer(Player, SubFlags);
        }
    }

	// Force the enemy to move to a specific location
	UFUNCTION()
	void ForceMoveTo(FVector Destination)
	{
		SetCapabilityAttributeVector(n"EnemyForceMoveTo", Destination);
	}

	// Check whether the enemy has line of sight to a particular player
	bool HasLineOfSightTo(AHazePlayerCharacter Player)
	{
		FLineOfSightData& Data = LineOfSightData[Player];

		float CurrentTime = Time::GetGameTimeSeconds();
		if (CurrentTime > Data.NextCalculation)
		{
			TArray<AActor> IgnoreActors;
			IgnoreActors.Add(this);
			IgnoreActors.Add(Player);
			FHitResult Hit;

			Data.bHasLineOfSight = !System::LineTraceSingleByProfile(
				Start = ActorCenterLocation,
				End = Player.ActorCenterLocation,
				ProfileName = bPlayerConditionalBlocksLOS ? n"Enemy" : n"PlayerCharacterIgnoreConditional",
				bTraceComplex = false,
				ActorsToIgnore = IgnoreActors,
				DrawDebugType = EDrawDebugTrace::None,
				OutHit = Hit,
				bIgnoreSelf = true
			);

			Data.NextCalculation = CurrentTime + LINE_OF_SIGHT_RECALC_INTERVAL * FMath::RandRange(0.5f, 1.5f);
		}

		return Data.bHasLineOfSight;
	}

	bool CanTargetPlayer(AHazePlayerCharacter Player)
	{
		if (Player.IsPlayerDead())
			return false;
		if (Player.bHidden)
			return false;
		if (IsPlayerHiddenFromEnemies(Player))
			return false;
		return true;
	}

    void SendMovementAnimationRequest(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag)
    {        
		if (!Mesh.CanRequestLocomotion())
			return;

        FHazeRequestLocomotionData AnimationRequest;
 
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;
        AnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
 		AnimationRequest.WantedVelocity = MoveData.Velocity;
        AnimationRequest.WantedWorldTargetDirection = MoveData.MovementDelta;
        AnimationRequest.WantedWorldFacingRotation = AIMovementComponent.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = AIMovementComponent.MoveSpeed;

		if (AIMovementComponent.IsGrounded())
			AnimationRequest.WantedVelocity.Z = 0.f;
		
		if(!AIMovementComponent.GetAnimationRequest(AnimationRequest.AnimationTag))
		{
			AnimationRequest.AnimationTag = AnimationRequestTag;
		}

        if (!AIMovementComponent.GetSubAnimationRequest(AnimationRequest.SubAnimationTag))
        {
            AnimationRequest.SubAnimationTag = SubAnimationRequestTag;
        }
		
		RequestLocomotion(AnimationRequest);
    }

	void BlockAutoDisable(bool bBlocked)
	{
		if (bBlocked)
		{
			if (AutoDisableBlocks == 0)
				DisableComponent.SetUseAutoDisable(false);
			AutoDisableBlocks += 1;
		}
		else
		{
			AutoDisableBlocks -= 1;
			if (AutoDisableBlocks == 0)
				DisableComponent.SetUseAutoDisable(true);
		}
	}
}

struct FLineOfSightData
{
	float NextCalculation = -1.f;
	bool bHasLineOfSight = false;
};
