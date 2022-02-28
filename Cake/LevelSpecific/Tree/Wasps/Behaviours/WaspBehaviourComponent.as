import Vino.Movement.Components.MovementComponent;
import Vino.AI.Components.GentlemanFightingComponent;
import Peanuts.Spline.SplineActor;
import Vino.Movement.Capabilities.KnockDown.CharacterKnockDownCapability;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;
import Vino.AI.Scenepoints.ScenepointComponent;
import Vino.AI.Scenepoints.ScenepointActor;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.Wasps.WaspTypes;

FName GetWaspStateTag(EWaspState State)
{
	switch(State)
	{
		case EWaspState::None: return NAME_None;
		case EWaspState::Idle: return n"WaspIdle";
		case EWaspState::Combat: return n"WaspCombat";
		case EWaspState::Telegraphing: return n"WaspTelegraphing";
		case EWaspState::Attack: return n"WaspAttack";
		case EWaspState::Grapple: return n"WaspGrapple";
		case EWaspState::Recover: return n"WaspRecover";
		case EWaspState::Stunned: return n"WaspStunned";
		case EWaspState::Flee: return n"WaspFlee";
	}

	return NAME_None;
}

enum EWaspBehaviourPriority
{
	None,
    Minimum,
    Low,
    Normal,
    High,
    Maximum,
}

event void FWaspOnAttackRunHit(AHazeActor Target);
event void FWaspOnAttackStarted(AHazeActor Attacker, AHazeActor Target);
event void FWaspOnUnspawn(AHazeActor Wasp);
event void FWaspOnEnabled(AHazeActor Wasp);
event void FWaspOnDisabled(AHazeActor Wasp);
event void FWaspOnFlee(AHazeActor Wasp);
event void FWaspOnTelegraphingAttack(AHazeActor Wasp);

class UWaspBehaviourComponent : UActorComponent
{
	UPROPERTY()
	AScenepointActor StartingScenepoint = nullptr;

	UPROPERTY()
	ASplineActor StartingSpline = nullptr;

	// Splines which we may flee along. We will alwyas flee towards the beginning of the spline, since we will want to reuse entry splines.
	UPROPERTY()
	TArray<ASplineActor> FleeingSplines;

    // Triggers whenever we make an attack run and score a hit
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnAttackRunHit OnAttackRunHit;

    // Triggers whenever we start an attack run
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnAttackStarted OnAttackStarted;

	// All movement will be relative to this component
	UPROPERTY()
	USceneComponent MovementBase = nullptr;

	// Triggers when we won't be entering play again and can be respawned
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnUnspawn OnUnspawn;

	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnEnabled OnEnabled;

	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnEnabled OnAliveForAWhile;

	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnDisabled OnDisabled;

	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnFlee OnFlee;

	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnTelegraphingAttack OnTelegraphingAttack;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
    UHazeAITeam Team = nullptr;

	UPROPERTY()
	UWaspComposableSettings DefaultSettings = nullptr;
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UWaspComposableSettings Settings;

	UPROPERTY(Category = "VOBark")
	UFoghornVOBankDataAssetBase VOBankDataAsset = nullptr;

	// Bark used when wasp first prepares to attack an enemy
	UPROPERTY(Category = "VOBark")
	UFoghornBarkDataAsset IntroBark = nullptr;

	// Bark used when taking damage
	UPROPERTY(Category = "VOBark")
	UFoghornBarkDataAsset TakeDamageBark = nullptr;

	// Bark used just before exploding
	UPROPERTY(Category = "VOBark")
	UFoghornBarkDataAsset DeathBark = nullptr;

	// Bark used when recovering from exhaustion after failing to hit the target
	UPROPERTY(Category = "VOBark")
	UFoghornBarkDataAsset ExhaustedFailBark = nullptr;

    AHazeCharacter CharOwner = nullptr;
    private AHazeActor CurrentTarget = nullptr;
    private UGentlemanFightingComponent CurrentGentlemanComp = nullptr;

    // The behaviour state we will begin in
    UPROPERTY(Category = "WaspBehaviour|State")
    EWaspState CurrentState = EWaspState::Idle;
    EWaspState StateLastUpdate = EWaspState::None;
    EWaspState PreviousState = EWaspState::None;
    float StateChangeTime = 0.f;

	EWaspState FindTargetExitState = EWaspState::Combat;

	EWaspBehaviourPriority CurrentActivePriority = EWaspBehaviourPriority::None;

    float SustainedAttackEndTime = 0.f;
	int SustainedAttackCount = 0;
    bool bHasPerformedSustainedAttack = false;

    float Acceleration = 0.f;
    FVector MovementDestination = FVector::ZeroVector;
	float MovementLockHeightStrength = 0.f;
	float MovementLockedHeight = 0.f;
    bool bHasFocus = false;
    FVector FocusLocation = FVector::ZeroVector;
	float LastAttackRunHitTime = 0.f;

	UHazeSplineComponent FollowSpline = nullptr;
	TArray<UHazeSplineComponent> FleeSplines;
	bool bFleeAfterStun = false;

	UScenepointComponent CurrentScenepoint = nullptr;

	UHazeSplineComponent MovingAlongSpline = nullptr;
	float DistanceAlongMoveSpline = 0.f;
	bool bSnapToMoveSpline = false;
	bool bMoveAlongSplineForwards = true;
	bool bHasSpotEnemyTaunted = false;

	UHazeSplineComponent PrevMoveSpline = nullptr;
	FVector PrevMoveSplineLocation = FVector::ZeroVector;

	// Variables to keep track of targets when on moving ground (such as on an elevator)
	UPrimitiveComponent TargetGroundComponent = nullptr;
	FHazeAcceleratedVector TargetGroundVelocity;
	float LastGroundedTime = 0.f;

	uint8 SingleShotsSinceSalvo = 0;

	AHazeActor LastAttackedTarget = nullptr;
	uint8 SameTargetAttackCount = 0;
	uint8 QuickAttackSequenceCount = 0;
	AHazeActor AggroTarget  = nullptr;

	UWaspHealthComponent HealthComp;
	UHazeCrumbComponent CrumbComp;

	void SetState(EWaspState State) property
	{
		// State is set on control side and replicated by capabilities
		if (HasControl())
			CurrentState = State; 
	}

	void SetRemoteState(EWaspState State) property
	{
		// Capabilities should use this when setting state on remote side
		if (!HasControl())
			CurrentState = State; 
	}

	EWaspState GetState() property
	{
		return CurrentState;
	}

	UFUNCTION()
	void StartFollowingSpline(UHazeSplineComponent Spline)
	{
		if (Spline != nullptr)
		{
			FollowSpline = Spline;
			
			// Immediately start following spline
			State = EWaspState::Idle; 
		}
	}
	
	UFUNCTION()
	void StopFollowingSpline()
	{
		FollowSpline = nullptr;
	}

	UFUNCTION()
	void UseScenepoint(UScenepointComponent Scenepoint)
	{
		CurrentScenepoint = Scenepoint;
	}

	UFUNCTION()
	void Flee()
	{
		for (ASplineActor SplineActor : FleeingSplines)
		{
			if (SplineActor.Spline != nullptr)
				FleeSplines.AddUnique(SplineActor.Spline);			
		}	

		if (HealthComp.IsSapped())
		{
			State = EWaspState::Stunned;			
			bFleeAfterStun = true;
		}
		else
		{
			State = EWaspState::Flee;
		}
	}

	// Waps will immediately start fleeing along one of the given splines (or set fleeing splines). Destination is the start of the spline since we will want to resue entry splines.
	UFUNCTION()
	void FleeAlongSpline(TArray<UHazeSplineComponent> Splines)
	{
		if (Splines.Num() > 0.f)
			FleeSplines = Splines;

		if ((Splines.Num() > 0.f) || (FleeingSplines.Num() > 0))
			Flee();
	}

	UFUNCTION()
	void ApplyIdleAcceleration(float Acceleration, UObject Instigator = nullptr)
	{
		Instigator = Game::AllowScriptInstigator(Instigator);
		UWaspComposableSettings TransientSettings = UWaspComposableSettings::TakeTransientSettings(CharOwner, Instigator, EHazeSettingsPriority::Script);
		TransientSettings.bOverride_IdleAcceleration = true;
		TransientSettings.IdleAcceleration = Acceleration;
		CharOwner.ReturnTransientSettings(TransientSettings);
	}

	UFUNCTION()
	void ClearIdleAccelerationByInstigator(float Acceleration, UObject Instigator = nullptr)
	{
		Instigator = Game::AllowScriptInstigator(Instigator);
		UWaspComposableSettings TransientSettings = UWaspComposableSettings::TakeTransientSettings(CharOwner, Instigator, EHazeSettingsPriority::Script);
		TransientSettings.bOverride_IdleAcceleration = false;
		CharOwner.ReturnTransientSettings(TransientSettings);
	}

	// Make this wasp attack the given target as soon as possible (it will not abort current attack).
	UFUNCTION()
	void SetAggro(AHazeActor Aggro)
	{
		AggroTarget = Aggro;
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CharOwner = Cast<AHazeCharacter>(GetOwner());
        Team = CharOwner.JoinTeam(Wasp::TeamName);
		HealthComp = UWaspHealthComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		ensure((CharOwner != nullptr) && (Team != nullptr) && (HealthComp != nullptr) && (CrumbComp != nullptr));

		if (StartingScenepoint != nullptr)
			UseScenepoint(StartingScenepoint.GetScenepoint());

		if (StartingSpline != nullptr)
			StartFollowingSpline(StartingSpline.Spline);

		// Set up default settings
		Settings = UWaspComposableSettings::GetSettings(CharOwner);
		if (ensure(DefaultSettings != nullptr))
			CharOwner.ApplySettings(DefaultSettings, this, EHazeSettingsPriority::Defaults);

        // Make sure players have gentleman fighting components
        TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
        for (AHazePlayerCharacter Player : Players)
        {
            // TODO: Remove this when there are no opponents left
            UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::GetOrCreate(Player);
			int NumAttackers = Player.IsMay() ? Settings.GentlemanMaxAttackersMay : Settings.GentlemanMaxAttackersCody;
			GentlemanComp.SetMaxAllowedClaimants(n"WaspAttack", NumAttackers);
        }

		// Make sure players have some common capabilities
		Team.AddPlayersCapability(UCharacterKnockDownCapability::StaticClass());

		// Enter starting state, unblocking those capabilities
		UpdateState(); 
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        CharOwner.LeaveTeam(Wasp::TeamName);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (CurrentGentlemanComp != nullptr)
		{
			if(CurrentGentlemanComp.GetMaxAllowedClaimants(n"IsAttackedAllowed") == 0)
			{
				CurrentGentlemanComp.SetMaxAllowedClaimants(n"WaspAttack", 0);
			}
			else
			{
				if (Game::GetMay() == CurrentGentlemanComp.Owner)
					CurrentGentlemanComp.SetMaxAllowedClaimants(n"WaspAttack", Settings.GentlemanMaxAttackersMay);			
				if (Game::GetCody() == CurrentGentlemanComp.Owner)
					CurrentGentlemanComp.SetMaxAllowedClaimants(n"WaspAttack", Settings.GentlemanMaxAttackersCody);		
			}
		}
		UpdateTargetGround(DeltaTime);
    }

	void UpdateTargetGround(float DeltaTime)
	{
		if (DeltaTime == 0.f)
			return;

		// When moving along spline, we adjust speed as if target was travelling with the spline
		if (MovingAlongSpline != nullptr)
		{
			FVector SplineVelocity = FVector::ZeroVector;
			if (PrevMoveSpline == MovingAlongSpline)
				SplineVelocity = (MovingAlongSpline.GetWorldLocation() - PrevMoveSplineLocation) / DeltaTime;
			PrevMoveSpline = MovingAlongSpline;
			PrevMoveSplineLocation = MovingAlongSpline.GetWorldLocation();				
			TargetGroundVelocity.AccelerateTo(SplineVelocity, 0.5f, DeltaTime);
			return;
		}
		PrevMoveSpline = nullptr;

		UHazeMovementComponent MoveComp = nullptr;
		if (IsValidTarget(Target)) 
			MoveComp = UHazeMovementComponent::Get(Target);
		if (MoveComp == nullptr)
		{
			TargetGroundComponent = nullptr;
			TargetGroundVelocity.AccelerateTo(FVector::ZeroVector, 1.f, DeltaTime);
			return;
		}

		UPrimitiveComponent GroundComp = Cast<UPrimitiveComponent>(MovementBase);
		if (GroundComp == nullptr)
		{
			FVector RelLoc;
			if (!MoveComp.GetCurrentMoveWithComponent(GroundComp, RelLoc))
				GroundComp = nullptr;
		}

		if (GroundComp != nullptr)			
		{
			TargetGroundComponent = GroundComp;
			LastGroundedTime = Time::GetGameTimeSeconds();
		}
		else if (Time::GetGameTimeSince(LastGroundedTime) > 2.f)
		{
			// Target has been ungrounded for too long, assume they've jumped/fallen off previous ground
			TargetGroundComponent = nullptr;
		}

		if (TargetGroundComponent == nullptr)
		{
			TargetGroundVelocity.AccelerateTo(FVector::ZeroVector, 1.f, DeltaTime);
			return;			
		}

		FVector GroundVel = TargetGroundComponent.GetPhysicsLinearVelocity();
		TargetGroundVelocity.AccelerateTo(GroundVel, 0.5f, DeltaTime);
	}

    void UpdateState()
    {
        if (State != StateLastUpdate)
        {
            PreviousState = StateLastUpdate;
            StateLastUpdate = State;
            StateChangeTime = Time::GetGameTimeSeconds();
			CurrentActivePriority = EWaspBehaviourPriority::None;

			if (State == EWaspState::Telegraphing)
				OnTelegraphingAttack.Broadcast(CharOwner);
			if (State == EWaspState::Flee)
				OnFlee.Broadcast(CharOwner);

			DebugEvent("Swapped state from " + GetWaspStateTag(PreviousState));
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
		if (HasControl() && (NewTarget != CurrentTarget))
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"Target", NewTarget);
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbSetTarget"), CrumbParams);
		}
    }

	UFUNCTION(NotBlueprintCallable)
	void CrumbSetTarget(const FHazeDelegateCrumbData& CrumbParams)
	{
		SetTargetInternal(Cast<AHazeActor>(CrumbParams.GetObject(n"Target")));
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
		return IsValidTarget(CurrentTarget);
	}

	private void SetTargetInternal(AHazeActor NewTarget)
	{
		if (NewTarget == CurrentTarget)
			return;

		if (CurrentGentlemanComp != nullptr)
        {
            CurrentGentlemanComp.Opponents.Remove(CharOwner);
            CurrentGentlemanComp.ReleaseAction(n"WaspAttack", CharOwner);            
        }

        CurrentGentlemanComp = nullptr;
        if (NewTarget != nullptr)
        {
            CurrentGentlemanComp = UGentlemanFightingComponent::Get(NewTarget);
            if (CurrentGentlemanComp != nullptr)
                CurrentGentlemanComp.Opponents.Add(CharOwner);
        }

		// Always abort any quick attack sequence when changing target
		AbortQuickAttackSequence();
        CurrentTarget = NewTarget;
	}

	void AbortQuickAttackSequence()
	{
		QuickAttackSequenceCount = 0;
		if (GentlemanComponent != nullptr)  
			GentlemanComponent.ReleaseAction(n"WaspAttack", Owner);
	}

    UGentlemanFightingComponent GetGentlemanComponent() property
    {
        return CurrentGentlemanComp;
    }

    FVector GetVelocity() property
    {
        return UHazeBaseMovementComponent::Get(CharOwner).GetVelocity(); 
    }

    bool CanHitTarget(AHazeActor CheckTarget, float Radius, float WithinSeconds, bool bCanHitBehind)
    {
        if (CheckTarget == nullptr)
            return false;

		// We can't hit targets if dead (when on Cody control side we can die before stopping all behaviours)
		if (HealthComp.bIsDead)
			return false;

        // Project target location on our predicted movement to see if we'll be passing target soon.
        FVector ProjectedTargetLocation;
        float ProjectedFraction = 1.f;
        FVector OwnLocation = CharOwner.GetActorLocation();
        FVector Vel = GetVelocity();
#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			System::DrawDebugCapsule(OwnLocation + Vel * WithinSeconds * 0.5f, Radius + Vel.Size() * WithinSeconds * 0.5f, Radius, FRotator(90,0,0).Compose(CharOwner.ActorForwardVector.Rotation()), FLinearColor::Red);
#endif
        if (!bCanHitBehind && Vel.IsNearlyZero(0.1f))
            Vel = CharOwner.GetActorForwardVector() * 0.1f; // Make sure we have something to relate 'behind' to
        if (!Math::ProjectPointOnLineSegment(OwnLocation, OwnLocation + Vel * WithinSeconds, CheckTarget.ActorCenterLocation, ProjectedTargetLocation, ProjectedFraction))
        {
            if (!bCanHitBehind && (ProjectedFraction == 0.f))
                return false; // We've passed target
        }

        if (ProjectedTargetLocation.DistSquared(CheckTarget.ActorCenterLocation) > FMath::Square(Radius))
            return false; // Passing target, but too far away

        // Close enough to hit target!
        return true;
    }

    FVector GetAttackRunDestination(AHazeActor CheckTarget)
    {
		if (CheckTarget == nullptr)
			return Owner.ActorLocation + Owner.ActorForwardVector * 500.f; 

        FVector Destination = CheckTarget.GetActorLocation();
        if (Settings.bAttackRunPrediction)
        {
            FVector PredictVelocity = CheckTarget.GetActualVelocity();
            PredictVelocity.Z = 0.f;
			PredictVelocity = PredictVelocity.GetClampedToMaxSize(800.f);
            Destination += PredictVelocity * 0.2f;
        }
        return Destination;
    }

    void PerformSustainedAttack(float Duration, int NumAttacks = 1)
    {
		bool bNewAttack = (Time::GetGameTimeSeconds() > SustainedAttackEndTime) || (Target != LastAttackedTarget);

        SustainedAttackEndTime = Time::GetGameTimeSeconds() + Duration;
		SustainedAttackCount = NumAttacks;
        bHasPerformedSustainedAttack = true;

		if (Target == AggroTarget)
			AggroTarget = nullptr;

		if (bNewAttack)
		{
			if (Target != LastAttackedTarget)
				SameTargetAttackCount = 1;
			else
				SameTargetAttackCount++;
			LastAttackedTarget = Target;
			OnAttackStarted.Broadcast(CharOwner, Target);
		}
    }

    void StopSustainedAttack()
    {
        SustainedAttackEndTime = Time::GetGameTimeSeconds();
		SustainedAttackCount = 0;
    }

	bool ShouldFireSalvo()
	{
		if (Settings.SalvoFrequency <= 0)
			return false;
		
		if (SingleShotsSinceSalvo + 1 < Settings.SalvoFrequency)
			return false;
			
		return true;
	}

    void MoveTo(const FVector& Destination, float Acc)
    {
       	MovementDestination = Destination; 
        Acceleration = Acc;
    }

	FVector GetMoveDestination() property
	{
       	return MovementDestination; 
	}

    void RotateTowards(const FVector& FocusLoc)
    {
        FocusLocation = FocusLoc;
        bHasFocus = true;
    }

	void MoveAlongSpline(UHazeSplineComponent Spline, float Acc, bool bForwards = true)
	{
		MovingAlongSpline = Spline;
		Acceleration = Acc;
		bMoveAlongSplineForwards = bForwards;
	}

	void LockMovementHeight(float LockHeight, float LockStrength)
	{
		MovementLockedHeight = LockHeight;
		MovementLockHeightStrength = LockStrength;
	}

    float GetGrappleCooldownTime() property
    {
        return Team.GetLastActionTime(n"WaspGrapple") + Settings.GrappleCooldown;
    }

    void ReportGrapple()
    {
        Team.ReportAction(n"WaspGrapple");
    }

    bool ClaimGentlemanAction(const FName& Tag, AHazeActor CheckTarget) 
    {
        UGentlemanFightingComponent GentlemanComp = CurrentGentlemanComp;
        if (CheckTarget != CurrentTarget)
            GentlemanComp = UGentlemanFightingComponent::Get(CheckTarget);

        if (GentlemanComp == nullptr)
            return true;
        
        if (GentlemanComp.ClaimAction(n"WaspAttack", CharOwner))
            return true;
        
        if (!Settings.bUseGentleManFighting)
        {
            // Note that we still claim action if possible, there may be actual 
            // gentlemen around who cares. 
            return true; 
        }

        // This is not a fair action!
        return false;
    }

	UFUNCTION()
	void SetGentlemanOverride(bool bIsGentleman, UObject Instigator = nullptr, EHazeSettingsPriority Prio = EHazeSettingsPriority::Script)
	{
		Instigator = Game::AllowScriptInstigator(Instigator);
		UWaspComposableSettings TransientSettings = UWaspComposableSettings::TakeTransientSettings(CharOwner, Instigator, Prio);
		TransientSettings.bOverride_bUseGentleManFighting = true;
		TransientSettings.bUseGentleManFighting = bIsGentleman;
		CharOwner.ReturnTransientSettings(TransientSettings);
	}
	UFUNCTION()
	void ClearGentlemanOverride(bool bIsGentleman, UObject Instigator = nullptr, EHazeSettingsPriority Prio = EHazeSettingsPriority::Script)
	{
		Instigator = Game::AllowScriptInstigator(Instigator);
		UWaspComposableSettings TransientSettings = UWaspComposableSettings::TakeTransientSettings(CharOwner, Instigator, Prio);
		TransientSettings.bOverride_bUseGentleManFighting = false;
		CharOwner.ReturnTransientSettings(TransientSettings);
	}

    FVector GetCirclingDestination(const FVector& TargetLoc, float CircleHeight, const FVector& PreferredDirection, float CircleDistance)
    {
        // Move towards target's flank, but push away when too close                 
        FVector OwnLoc = CharOwner.GetActorLocation();
        FVector ToTarget = (TargetLoc - OwnLoc).GetSafeNormal2D();
        FVector ToTargetOrthogonal = ToTarget.CrossProduct(FVector::UpVector);
        if (ToTargetOrthogonal.DotProduct(PreferredDirection) < 0.f)
            ToTargetOrthogonal = -ToTargetOrthogonal;
        
        FVector CircleDest = TargetLoc + ToTargetOrthogonal * CircleDistance; 
        if (OwnLoc.DistSquared2D(TargetLoc) < FMath::Square(CircleDistance))
            CircleDest -= ToTarget * (1.0f - (OwnLoc.Dist2D(TargetLoc) / CircleDistance)) * CircleDistance;    

        CircleDest.Z = TargetLoc.Z + CircleHeight;
        return  CircleDest;
    }

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		if (HealthComp.bIsDead || (State == EWaspState::Flee))
			OnUnspawn.Broadcast(CharOwner);
		State = EWaspState::None;
		SustainedAttackEndTime = 0;
		SetTargetInternal(nullptr);

		USapResponseComponent SapComp = USapResponseComponent::Get(CharOwner);
		if (SapComp != nullptr)
			DisableAllSapsAttachedTo(Owner.RootComponent);

		CharOwner.BlockMovementSyncronization(this);

		OnDisabled.Broadcast(CharOwner);
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		State = EWaspState::Idle;

		CharOwner.CleanupCurrentMovementTrail();
		CharOwner.UnblockMovementSyncronization(this);
		OnEnabled.Broadcast(CharOwner);
		System::SetTimer(this, n"OnPostEnableDelay", 0.5f, false);
	}

	UFUNCTION()
	void OnPostEnableDelay()
	{
		if (!HealthComp.bIsDead && !CharOwner.IsActorDisabled())
			OnAliveForAWhile.Broadcast(CharOwner);
	}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		SetState(EWaspState::Idle);
		CurrentActivePriority = EWaspBehaviourPriority::None;
		SetTargetInternal(nullptr);

		SustainedAttackEndTime = 0;
		bHasPerformedSustainedAttack = false;
		SingleShotsSinceSalvo = 0;

		MovingAlongSpline = nullptr;
		FleeSplines.Empty();
		bFleeAfterStun = false;
		FollowSpline = nullptr;
		PrevMoveSpline = nullptr;
		bHasSpotEnemyTaunted = false;

		TargetGroundComponent = nullptr;
		LastGroundedTime = 0.f;

		LastAttackedTarget = nullptr;
		SameTargetAttackCount = 0;
		AggroTarget = nullptr;

		MovementBase = nullptr;
		CharOwner.DetachFromActor(EDetachmentRule::KeepWorld);

		ShowMeshes();
	}

	void HideMeshes()
	{
		TArray<UActorComponent> MeshComps = Owner.GetComponentsByClass(UMeshComponent::StaticClass());
		for (UActorComponent Comp : MeshComps)
		{
			UMeshComponent MeshComp = Cast<UMeshComponent>(Comp);
			if (MeshComp != nullptr)
				MeshComp.SetHiddenInGame(true); 
		}
	}
	void ShowMeshes()
	{
		TArray<UActorComponent> MeshComps = Owner.GetComponentsByClass(UMeshComponent::StaticClass());
		for (UActorComponent Comp : MeshComps)
		{
			UMeshComponent MeshComp = Cast<UMeshComponent>(Comp);
			if (MeshComp != nullptr)
				MeshComp.SetHiddenInGame(false); 
		}
	}

	// Debug functions
	void DebugEvent(FString Description)
	{
		//Log((HasControl() ? "CONTROL" : "REMOTE") + " (" + Time::GetGameTimeSeconds() + ") " + CharOwner.GetName() + " " + Description + ", State is " + GetWaspStateTag(State));	
	}
}


