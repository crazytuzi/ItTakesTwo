import Vino.Movement.Components.MovementComponent;
import Vino.AI.Components.GentlemanFightingComponent;
import Peanuts.Spline.SplineActor;
import Vino.Movement.Capabilities.KnockDown.CharacterKnockDownCapability;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Vino.AI.Scenepoints.ScenepointComponent;
import Vino.AI.Scenepoints.ScenepointActor;
import Vino.PlayerHealth.PlayerHealthStatics;

// Fishs have several behaviour states each in which one or more behaviour capabilities are possible
enum EFishState
{
    None,
    Idle,
    Combat,
    Attack,
    Recover,
	Flee,

	MAX
}

FName GetFishStateTag(EFishState State)
{
	switch (State)
	{
		case EFishState::None: return NAME_None;
		case EFishState::Idle: return n"FishIdle";
		case EFishState::Combat: return n"FishCombat";
		case EFishState::Attack: return n"FishAttack";
		case EFishState::Recover: return n"FishRecover";
		case EFishState::Flee: return n"FishFlee";
	}
    return NAME_None;
}

enum EFishBehaviourPriority
{
	None,
    Minimum,
    Low,
    Normal,
    High,
    Maximum,
}

event void FFishOnAttackRunHit(AHazeActor Target);
event void FFishOnSpotTarget(AHazeActor Target);

class UFishBehaviourComponent : UActorComponent
{
	UPROPERTY()
	AScenepointActor StartingScenepoint = nullptr;

	UPROPERTY()
	ASplineActor StartingSpline = nullptr;

	// Splines which we may flee along. We will alwyas flee towards the beginning of the spline, since we will want to reuse entry splines.
	UPROPERTY()
	TArray<ASplineActor> FleeingSplines;

	UPROPERTY()
	UStaticMeshComponent VisionCone = nullptr;

	UPROPERTY()
	USphereComponent VisionSphere = nullptr;

	UPROPERTY()
	USceneComponent AttackHitDetectionCenter = nullptr;

    // Triggers whenever we make an attack run and score a hit
	UPROPERTY(meta = (NotBlueprintCallable))
	FFishOnAttackRunHit OnAttackRunHit;

    // Triggers whenever we spot a new target
	UPROPERTY(meta = (NotBlueprintCallable))
	FFishOnSpotTarget OnSpotTarget;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
    UHazeAITeam Team = nullptr;

    UPROPERTY()
    TSubclassOf<UPlayerDeathEffect> PlayerDeathEffect;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset LungeCameraSettings = Asset("/Game/Blueprints/LevelSpecific/SnowGlobe/Swimming/UnderwaterMechanics/AnglerFish/DA_CamSettings_FishLunge");

	UPROPERTY()
	TArray<UCapsuleComponent> PushCapsules;

	UPROPERTY()
	UFishComposableSettings DefaultSettings = nullptr;
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UFishComposableSettings Settings;

	UPROPERTY()
	UCurveFloat PrepareLungeTurnSpeedCurve = nullptr;

    AHazeCharacter CharOwner = nullptr;
    private AHazeActor CurrentTarget = nullptr;
    private UGentlemanFightingComponent CurrentGentlemanComp = nullptr;

    // The behaviour state we will begin in
    UPROPERTY(Category = "FishBehaviour|State")
    EFishState CurrentState = EFishState::Idle;
    EFishState StateLastUpdate = EFishState::None;
    EFishState PreviousState = EFishState::None;
    float StateChangeTime = 0.f;

	EFishBehaviourPriority CurrentActivePriority = EFishBehaviourPriority::None;

    float SustainedAttackEndTime = 0.f;
	TArray<AHazeActor> Food;

    float MovementAcceleration = 0.f;
	float MovementTurnDuration = 10.f;
    FVector MovementDestination = FVector::ZeroVector;
    bool bHasFocus = false;
    FVector FocusLocation = FVector::ZeroVector;

	UHazeSplineComponent FollowSpline = nullptr;
	TArray<UHazeSplineComponent> FleeSplines;

	UScenepointComponent CurrentScenepoint = nullptr;
	UScenepointComponent InvestigateScenepoint = nullptr;

	UHazeSplineComponent MovingAlongSpline = nullptr;
	float DistanceAlongMoveSpline = 0.f;
	bool bSnapToMoveSpline = false;
	bool bMoveAlongSplineForwards = true;
	bool bHasSpotEnemyTaunted = false;

	UHazeSplineComponent PrevMoveSpline = nullptr;
	FVector PrevMoveSplineLocation = FVector::ZeroVector;

	// Fish must not be disabled when it's started to or is preparing to flee
	bool bAllowDisable = true;

	void SetState(EFishState State) property
	{
		// State is set on control side and replicated by behaviour capabilities
		if (HasControl())
			CurrentState = State; 
	}

	void SetRemoteState(EFishState State) property
	{
		// Capabilities should use this when setting state on remote side
		if (!HasControl())
			CurrentState = State; 
	}

	EFishState GetState() property
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
			State = EFishState::Idle; 
		}
	}
	
	UFUNCTION()
	void StopFollowingSpline()
	{
		FollowSpline = nullptr;
	}

	UFUNCTION()
	void Investigate(UScenepointComponent Scenepoint)
	{
		// Fish will become curious about given scene point
		InvestigateScenepoint = Scenepoint;
		System::ClearTimer(this, "ForgetInvestigation");
		System::SetTimer(this, n"ForgetInvestigation", 5.f, false);
	}

	UFUNCTION()
	void ForgetInvestigation()
	{
		InvestigateScenepoint = nullptr;
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

		State = EFishState::Flee;
	}

	UFUNCTION()
	void ApplyIdleAcceleration(float Acceleration, UObject Instigator = nullptr)
	{
		Instigator = Game::AllowScriptInstigator(Instigator);
		UFishComposableSettings TransientSettings = UFishComposableSettings::TakeTransientSettings(CharOwner, Instigator, EHazeSettingsPriority::Script);
		TransientSettings.bOverride_IdleAcceleration = true;
		TransientSettings.IdleAcceleration = Acceleration;
		CharOwner.ReturnTransientSettings(TransientSettings);
	}

	UFUNCTION()
	void ClearIdleAccelerationByInstigator(float Acceleration, UObject Instigator = nullptr)
	{
		Instigator = Game::AllowScriptInstigator(Instigator);
		UFishComposableSettings TransientSettings = UFishComposableSettings::TakeTransientSettings(CharOwner, Instigator, EHazeSettingsPriority::Script);
		TransientSettings.bOverride_IdleAcceleration = false;
		CharOwner.ReturnTransientSettings(TransientSettings);
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CharOwner = Cast<AHazeCharacter>(GetOwner());
        Team = CharOwner.JoinTeam(n"FishTeam");
		ensure((CharOwner != nullptr) && (Team != nullptr));

		if (StartingScenepoint != nullptr)
			UseScenepoint(StartingScenepoint.GetScenepoint());

		if (StartingSpline != nullptr)
			StartFollowingSpline(StartingSpline.Spline);

		// Set up default settings
		Settings = UFishComposableSettings::GetSettings(CharOwner);
		if (ensure(DefaultSettings != nullptr))
			CharOwner.ApplySettings(DefaultSettings, this, EHazeSettingsPriority::Defaults);

		// Make sure players have some common capabilities
		Team.AddPlayersCapability(UCharacterKnockDownCapability::StaticClass());

		// Enter starting state, unblocking those capabilities
		UpdateState(); 

		//if (HackMH != nullptr)
		//	Owner.PlaySlotAnimation(Animation = HackMH, bLoop = true);

		// Hack backup hit detection comp
		if (AttackHitDetectionCenter == nullptr)
			AttackHitDetectionCenter = UCapsuleComponent::Get(Owner);
    }

	UPROPERTY()
	UAnimSequence HackMH = Asset("/Game/Animations/Characters/Enemies/SnowGlobe/Anglerfish/Anglerfish_mh.Anglerfish_mh");

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        CharOwner.LeaveTeam(n"FishTeam");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			FLinearColor StateColor = FLinearColor::White;
			switch (CurrentState) {case EFishState::Attack: StateColor = FLinearColor::Red; break; case EFishState::Combat: StateColor = FLinearColor::Yellow; break; case EFishState::Recover: StateColor = FLinearColor::Green; break;};
			System::DrawDebugSphere(Owner.ActorLocation + Owner.ActorUpVector * 2500.f, 500.f, 4, StateColor, 0.f, 60.f);
		}
#endif
    }

    void UpdateState()
    {
        if (State != StateLastUpdate)
        {
            PreviousState = StateLastUpdate;
            StateLastUpdate = State;
            StateChangeTime = Time::GetGameTimeSeconds();
	 		CurrentActivePriority = EFishBehaviourPriority::None;

			DebugEvent("Swapped state from " + GetFishStateTag(PreviousState));
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

	bool HasValidTarget()
	{
		return CanHuntTarget(CurrentTarget);
	}

	// This function must be called on both sides in network, synced by crumb (e.g. on state activation/deactivation or crumb delegate)
    void SetTarget(AHazeActor NewTarget) property
    {
        if (CurrentTarget == NewTarget)
            return;

        CurrentTarget = NewTarget;
        CurrentGentlemanComp = nullptr;
        if (NewTarget != nullptr)
		{
            CurrentGentlemanComp = UGentlemanFightingComponent::Get(NewTarget);

			// Switch to target control side. Previous control side will have to wait in current state 
			// until remote side catches up, sets itself as control and start dropping crumbs
			CharOwner.SetControlSide(NewTarget);
			CharOwner.CleanupCurrentMovementTrail();

			OnSpotTarget.Broadcast(NewTarget);
		}
	}

	bool CanHuntTarget(AHazeActor CheckTarget)
	{
		if (CheckTarget == nullptr)
			return false;

		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(CheckTarget);
		if (GentlemanComp == nullptr)
			return false;
		
		if (!GentlemanComp.HasTag(n"FishPrey")) 
			return false;
		
		if (GentlemanComp.HasTag(n"FishHiding"))
			return false;

		if (!IsValidTarget(CheckTarget))
			return false;

		return true;
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

    UGentlemanFightingComponent GetGentlemanComponent() property
    {
        return CurrentGentlemanComp;
    }

    FVector GetVelocity() property
    {
        return UHazeBaseMovementComponent::Get(Owner).GetVelocity(); 
    }

	FVector GetMawForwardVector() property
	{
		const FQuat Offset = FQuat(FRotator(90.f, 0.f, 0.f));
		return (CharOwner.Mesh.GetSocketQuaternion(n"Head") * Offset).ForwardVector; 
	}

	bool IsInVisionSphere(FVector Location, float Padding)
	{
		if (VisionSphere == nullptr)
			return false;

		if (VisionSphere.WorldLocation.IsNear(Location, VisionSphere.GetScaledSphereRadius() + Padding))
			return true;
		return false;
	}

	bool IsInVisionCone(FVector Location, float Padding)
	{
		if (VisionCone == nullptr)
			return false;

		// TODO: Partial code duplication with select target capability. Find an elegant way of sharing if we want to allow players to escape vision cone.
		// Set up transform for vision cone
	 	FTransform Transform = VisionCone.WorldTransform;
		float Length = Transform.Scale3D.Z * 100.f;
		float EndRadius = Transform.Scale3D.X * 50.f;
		Transform.ConcatenateRotation(FQuat(FRotator(-90.f,0.f,0.f))); // Point bottom of cone forward
		FVector Dir = Transform.Rotation.ForwardVector;
		Transform.SetLocation(Transform.Location - Dir * Length * 0.5f); // Place location at point (where lantern is)
		Transform.Scale3D = FVector::OneVector;
		FTransform VisionWorldToLocal = Transform.Inverse();

		FVector LocalLoc = VisionWorldToLocal.TransformPosition(Location);
		if ((LocalLoc.X < -Padding) || (LocalLoc.X > Length + Padding))
			return false;
		
		// In front and not too far away, check radius 
		float DistFromCenterSqr = FMath::Square(LocalLoc.Y) + FMath::Square(LocalLoc.Z);
		float RadiusAtTarget = FMath::Clamp(LocalLoc.X, 0.f, Length) * EndRadius / Length;
		if (DistFromCenterSqr > FMath::Square(RadiusAtTarget + Padding))
			return false;
		
		// Within cone!
		return true;
	}

    bool CanHitTarget(AHazeActor CheckTarget, float Radius, float WithinSeconds)
    {
		// We can only hit targets on their control side
		if (!CheckTarget.HasControl())	
			return false;

        if (!IsValidTarget(CheckTarget))
            return false;

        // Project target location on our predicted movement relative to target to see if we'll be passing target soon.
        FVector ProjectedTargetLocation;
        float ProjectedFraction = 1.f;
		FVector RelativeVelocity = GetVelocity(); 
		RelativeVelocity -= Owner.ActorForwardVector * Owner.ActorForwardVector.DotProduct(CheckTarget.ActorVelocity);
        FVector VelocityOffset = RelativeVelocity * WithinSeconds;
        FVector TopLocation = AttackHitDetectionCenter.GetWorldLocation() + VelocityOffset;
		FVector BottomLocation = TopLocation - Owner.ActorUpVector * 1000.f; 

        Math::ProjectPointOnLineSegment(TopLocation, BottomLocation , CheckTarget.GetActorLocation(), ProjectedTargetLocation, ProjectedFraction);
        if (ProjectedTargetLocation.DistSquared(CheckTarget.GetActorLocation()) < FMath::Square(Radius))
            return true; // Target will be within reach of maw imminently

		// Check if target is already in our maw
		FVector MawLocation = AttackHitDetectionCenter.GetWorldLocation() - Owner.ActorUpVector * 400.f - Owner.ActorForwardVector * 500.f; 

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool && (CheckTarget == GetTarget()))
		{
			System::DrawDebugSphere(MawLocation, Radius, 40, FLinearColor::Yellow);
			System::DrawDebugSphere(TopLocation, Radius, 40, FLinearColor::Red);
			System::DrawDebugSphere(BottomLocation, Radius, 40, FLinearColor::Red);
		}
#endif		

		if (MawLocation.IsNear(CheckTarget.ActorLocation, Radius))
			return true;

        // Target is not near enough
        return false;
    }

    FVector GetAttackRunDestination(AHazeActor CheckTarget)
    {
        FVector Destination = CheckTarget.GetActorLocation();
        if (Settings.bAttackRunPrediction)
        {
            FVector PredictVelocity = CheckTarget.GetActualVelocity();
            Destination += PredictVelocity * 0.2f;
        }
        return Destination;
    }

    void PerformSustainedAttack(float Duration, int NumAttacks = 1)
    {
        SustainedAttackEndTime = Time::GetGameTimeSeconds() + Duration;
    }

    void StopSustainedAttack()
    {
        SustainedAttackEndTime = Time::GetGameTimeSeconds();
    }

    void MoveTo(const FVector& Destination, float Acceleration, float TurnDuration)
    {
       	MovementDestination = Destination; 
        MovementAcceleration = Acceleration;
		MovementTurnDuration = TurnDuration;
    }

	FVector GetMoveDestination() property
	{
       	return MovementDestination; 
	}

	void MoveAlongSpline(UHazeSplineComponent Spline, float Acc, bool bForwards = true)
	{
		MovingAlongSpline = Spline;
		MovementAcceleration = Acc;
		bMoveAlongSplineForwards = bForwards;
	}

    FVector GetCirclingDestination(const FVector& TargetLoc, float CircleHeight, const FVector& PreferredDirection, float CircleDistance)
    {
        // Move towards target's flank, but push away when too close                 
        FVector OwnLoc = Owner.GetActorLocation();
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
		if (!bAllowDisable)
			return true;

		State = EFishState::None;
		SustainedAttackEndTime = 0;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		CharOwner.JoinTeam(n"FishTeam");
		State = EFishState::Idle;
	}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		SetState(EFishState::Idle);
		CurrentTarget = nullptr;
		CurrentGentlemanComp = nullptr;
 		CurrentActivePriority = EFishBehaviourPriority::None;
		 
		SustainedAttackEndTime = 0;
		Food.Empty();

		FleeSplines.Empty();
		FollowSpline = nullptr;
		PrevMoveSpline = nullptr;
		bHasSpotEnemyTaunted = false;

		Owner.DetachFromActor(EDetachmentRule::KeepWorld);
	}

	// Debug functions
	void DebugEvent(FString Description)
	{
#if EDITOR
		if (bHazeEditorOnlyDebugBool)
			Log((HasControl() ? "CONTROL" : "REMOTE") + " (" + Time::GetGameTimeSeconds() + ") " + Owner.GetName() + " " + Description + ", State is " + GetFishStateTag(State));	
#endif
	}
}


