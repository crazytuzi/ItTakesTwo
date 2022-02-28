import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingSettings;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCollisionSolver;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingDebugWidget;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingBoostWidget;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingMagnetBoostGate;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingBlade;

class UIceSkatingEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter OwnerPlayer;

	UPROPERTY(BlueprintReadOnly)
	UIceSkatingComponent SkateComp;

	void InitInternal(UIceSkatingComponent Owner)
	{
		SetWorldContext(Owner);
		OwnerPlayer = Cast<AHazePlayerCharacter>(Owner.Owner);
		SkateComp = Owner;

		Init();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void Init() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnIceSkatingStarted() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnIceSkatingEnded() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTick(float DeltaTime) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStartFastMovement() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnEndFastMovement() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnBoost() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnAirBoost() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetGateGrab(AIceSkatingMagnetBoostGate Gate) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetGateRelease(AIceSkatingMagnetBoostGate Gate) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetGateBoost(AIceSkatingMagnetBoostGate Gate) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSoftImpact(FVector ImpactLocation) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnHardImpact(FVector ImpactLocation) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSkidStarted() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSkidEnded() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnHardBreakStarted() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnHardBreakEnded() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSkidRight(float Strength) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSkidRightEnded() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSkidLeft(float Strength) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSkidLeftEnded() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnAirGlideStarted() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnAirGlideEnded() {}
}

class UIceSkatingComponent : UActorComponent
{
	bool bIsIceSkating = false;
	float MaxSpeed = 0.f;
	bool bIsFast = false;

	bool bForceEnter = false;

	bool bForceAirGlide = false;

	bool bInstantImpactDeath = false;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset StateMachineAsset_Cody;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset StateMachineAsset_May;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase StumbleFeature_Cody;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase StumbleFeature_May;

	UPROPERTY(Category = "Animation")
	TSubclassOf<AIceSkatingBlade> BladeClass;

	UHazeLocomotionFeatureBase GetStumbleFeature() property
	{
		return Owner == Game::Cody ? StumbleFeature_Cody : StumbleFeature_May;
	}

	UPROPERTY(Category = "Debug")
	TSubclassOf<UIceSkatingDebugWidget> DebugWidget;

	UPROPERTY(Category = "UI")
	TSubclassOf<UIceSkatingBoostWidget> BoostWidget;

	/* These values are meant to be read from ABPs */
	UPROPERTY(Category = "Animation", NotEditable)
	bool bAnimRightFoot = true;

	UPROPERTY(Category = "Animation", NotEditable)
	bool bHasMovementInput = true;

	UPROPERTY(Category = "Animation", NotEditable)
	bool bIsSkidding = false;

	UPROPERTY(Category = "Animation", NotEditable)
	bool bShouldAirGlide = false;

	UPROPERTY(Category = "Animation", NotEditable)
	bool bGoingIntoWater = false;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect MagnetGateFeedbackEffect;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect StumbleEffect;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect SoftImpactEffect;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect HardImpactEffect;

	UPROPERTY(Category = "Events")
	TArray<TSubclassOf<UIceSkatingEventHandler>> EventHandlerTypes;
	TArray<UIceSkatingEventHandler> EventHandlers;

	// Input pausing stuff!
	float InputPauseTimer = -1.f;
	float InputPauseDuration = -1.f;
	// This timer is used as a fail-safe if you hit ground right after a boost-gate or something
	//	causing the input pausing to be prematurely interrupted.
	// If you enter air movement, we also dont want you to become grounded again while the grace timer is active.
	float InputPauseGraceTimer = -1.f;

	// Used to make sure theres a bit of delay in-between jumps
	float LastJumpTime = 0.f;

	FVector PlayerInputDirection;

	// Magnet gate stuff
	UPROPERTY(BlueprintReadOnly)
	AIceSkatingMagnetBoostGate ActiveBoostGate;

	// Grinding stuff
	FHazeSplineSystemPosition ForceJumpPosition;
	bool bGrindJumpShouldBlockInput = false;

	// Ground-projection for when we're in air
	FHitResult ProjectedGroundHit;

	// Used for common cooldown for hard/soft impacts
	float NextImpactTime;

	// Cheering enabling/disabling
	TSet<FName> CheerEnableNames;
	TSet<FName> CheerBlockNames;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Spawn the event handlers!
		for(auto HandlerType : EventHandlerTypes)
		{
			auto Handler = Cast<UIceSkatingEventHandler>(NewObject(this, HandlerType));
			EventHandlers.Add(Handler);

			Handler.InitInternal(this);
		}
	}

	/* EVENTS */
	void CallOnIceSkatingStartedEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnIceSkatingStarted();
	}
	void CallOnIceSkatingEndedEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnIceSkatingEnded();
	}
	void CallOnTickEvent(float DeltaTime)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTick(DeltaTime);
	}
	void CallOnImpactEvent(FHitResult Hit)
	{
		for(auto Handler : EventHandlers)
			Handler.OnImpact(Hit);
	}
	void CallOnStartFastMovementEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnStartFastMovement();
	}
	void CallOnEndFastMovementEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnEndFastMovement();
	}
	void CallOnBoostEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnBoost();
	}
	void CallOnAirBoostEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnAirBoost();
	}
	void CallOnMagnetGateGrab(AIceSkatingMagnetBoostGate Gate)
	{
		for(auto Handler : EventHandlers)
			Handler.OnMagnetGateGrab(Gate);
	}
	void CallOnMagnetGateRelease(AIceSkatingMagnetBoostGate Gate)
	{
		for(auto Handler : EventHandlers)
			Handler.OnMagnetGateRelease(Gate);
	}
	void CallOnMagnetGateBoost(AIceSkatingMagnetBoostGate Gate)
	{
		for(auto Handler : EventHandlers)
			Handler.OnMagnetGateBoost(Gate);
	}
	void CallOnSoftImpactEvent(FVector ImpactLocation)
	{
		for(auto Handler : EventHandlers)
			Handler.OnSoftImpact(ImpactLocation);
	}
	void CallOnHardImpactEvent(FVector ImpactLocation)
	{
		for(auto Handler : EventHandlers)
			Handler.OnHardImpact(ImpactLocation);
	}
	void CallOnSkidStartedEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnSkidStarted();
	}
	void CallOnSkidEndedEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnSkidEnded();
	}
	void CallOnSkidRight(float Strength)
	{
		for(auto Handler : EventHandlers)
			Handler.OnSkidRight(Strength);
	}
	void CallOnSkidRightEnded()
	{
		for(auto Handler : EventHandlers)
			Handler.OnSkidRightEnded();
	}
	void CallOnSkidLeft(float Strength)
	{
		for(auto Handler : EventHandlers)
			Handler.OnSkidLeft(Strength);
	}
	void CallOnSkidLeftEnded()
	{
		for(auto Handler : EventHandlers)
			Handler.OnSkidLeftEnded();
	}
	void CallOnHardBreakStarted()
	{
		for(auto Handler : EventHandlers)
			Handler.OnHardBreakStarted();
	}
	void CallOnHardBreakEnded()
	{
		for(auto Handler : EventHandlers)
			Handler.OnHardBreakEnded();
	}
	void CallOnAirGlideStartedEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnAirGlideStarted();
	}
	void CallOnAirGlideEndedEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnAirGlideEnded();
	}
	/* EVENTS */

	// Last grounded normal
	// Used for some air movement stuff and camera
	FVector LastGroundedNormal;

	FVector GetScaledPlayerInput() const
	{
		float InputScale = 1.f;
		if (IsInputPaused())
		{
			InputScale = 1.f - InputPauseTimer / InputPauseDuration;
		}

		return PlayerInputDirection * InputScale;
	}

	FVector GetScaledPlayerInput_VelocityRelative() const
	{
		return GetVelocityRelativeInput(GetScaledPlayerInput());
	}

	FHazeFrameMovement MakeFrameMovement(FName InName) const
	{
		const TSubclassOf<UHazeCollisionSolver> SolverClass(UIceSkatingCollisionSolver::StaticClass());

		auto MoveComp = UHazeMovementComponent::Get(Owner);
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(InName);
		FrameMove.ApplyAndConsumeImpulses();
		FrameMove.OverrideCollisionSolver(SolverClass);
		FrameMove.ApplyTargetRotationDelta();

		return FrameMove;
	}

	FVector TransformVectorToGround(FVector Vec) const
	{
		auto MovementComp = UHazeMovementComponent::Get(Owner);
		return TransformVectorToPlane(Vec, GetGroundNormal());
	}

	FVector TransformVectorToPlane(FVector Vec, FVector Normal) const
	{
		auto MovementComp = UHazeMovementComponent::Get(Owner);

		FVector Vec_Transformed = Math::ConstrainVectorToSlope(Vec, Normal, MovementComp.WorldUp);
		return Vec_Transformed.GetSafeNormal() * Vec.Size();
	}

	FVector GetVelocityRelativeInput(FVector Input) const
	{
		auto MoveComp = UHazeMovementComponent::Get(Owner);

		FVector Forward = MoveComp.Velocity;
		FVector Right = MoveComp.WorldUp.CrossProduct(Forward);

		Forward.Normalize();
		Right.Normalize();

		return FVector(Input.DotProduct(Forward), Input.DotProduct(Right), 0.f);
	}

	UFUNCTION(BlueprintPure, Category = "Physics")
	FVector GetGroundNormal() const property
	{
		auto Hit = GetGroundHit();
		if (!Hit.bBlockingHit)
			return FVector::UpVector;

		return Hit.Normal;
	}

	FVector GetSlopeDownwards() const property
	{
		FVector Normal = GroundNormal;
		FVector SlopeRight = Normal.CrossProduct(FVector::UpVector);
		FVector SlopeDown = Normal.CrossProduct(SlopeRight);

		return SlopeDown.GetSafeNormal();
	}

	FHitResult GetGroundHit() const property
	{
		auto MovementComp = UHazeMovementComponent::Get(Owner);
		return MovementComp.Impacts.DownImpact;
	}

	float GetGroundSlope() const property
	{
		return SlopeDownwards.DotProduct(FVector::UpVector);
	}

	FVector SlerpVectorTowardsAroundAxis(FVector Vector, FVector Target, FVector Axis, float Alpha) const
	{
		FVector Vector_Flat = Vector.ConstrainToPlane(Axis);
		FVector Target_Flat = Target.ConstrainToPlane(Axis);
		Vector_Flat.Normalize();
		Target_Flat.Normalize();

		float Q_Angle = FMath::Acos(Vector_Flat.DotProduct(Target_Flat));
		FVector Q_Axis = Vector_Flat.CrossProduct(Target_Flat);
		Q_Axis.Normalize();

		FQuat RotateQuat(Q_Axis, Q_Angle * Alpha);
		return RotateQuat * Vector;
	}

	FVector Turn(FVector Vector, float AngleDegrees) const
	{
		FQuat RotateQuat(GroundNormal, AngleDegrees * DEG_TO_RAD);
		return RotateQuat * Vector;
	}

	bool ShouldBeGrounded() const
	{
		const FIceSkatingAirSettings AirSettings;
		auto MovementComp = UHazeMovementComponent::Get(Owner);

		if (MovementComp.IsAirborne())
			return true;

		return MovementComp.Velocity.DotProduct(GroundNormal) > AirSettings.EscapeSpeed;
	}

	FVector ApplyMaxSpeedFriction(FVector Velocity, float DeltaTime)
	{
		FIceSkatingFastSettings FastSettings;
		FVector HoriVelocity;
		FVector VertVelocity;

		Math::DecomposeVector(VertVelocity, HoriVelocity, Velocity, GroundNormal);

		// We only wanna apply friction in the horizontal direction
		float Speed = HoriVelocity.Size();

		if (Speed > FastSettings.MaxSpeed_Hard)
		{
			Speed = FMath::Lerp(Speed, MaxSpeed, FastSettings.MaxSpeedBrake_Hard * DeltaTime);
		}
		else if (Speed > MaxSpeed)
		{
			// Apply less friction if we're going really fast
			float MaxSpeedPercentage = Math::GetPercentageBetween(FastSettings.MaxSpeed_Flat, FastSettings.MaxSpeed_Slope, MaxSpeed);
			float Friction = FMath::Lerp(FastSettings.MaxSpeedBrake_Max, FastSettings.MaxSpeedBrake_Min, MaxSpeedPercentage);
			Speed = FMath::Lerp(Speed, MaxSpeed, Friction * DeltaTime);
		}
		else
		{
			return Velocity;
		}

		return HoriVelocity.GetSafeNormal() * Speed + VertVelocity;
	}

	UFUNCTION(BlueprintPure, Category = "Animation")
	float GetSlopeRoll() const property
	{
		FVector ActorForward = Owner.ActorForwardVector;
		FVector ActorUp = Owner.ActorUpVector;
		FVector Normal = GetGroundNormal();
		FVector Right = ActorUp.CrossProduct(ActorForward);
		return FMath::Asin(Right.DotProduct(Normal)) * RAD_TO_DEG;
	}

	void PauseInput(float Duration)
	{
		FIceSkatingInputSettings InputSettings;

		InputPauseTimer = InputPauseDuration = Duration;
		InputPauseGraceTimer = InputSettings.InputPauseGraceDuration;
	}

	bool IsInputPaused() const
	{
		return InputPauseTimer > 0.f && InputPauseDuration > 0.f;
	}

	void StartJumpCooldown()
	{
		LastJumpTime = Time::GetGameTimeSeconds();
	}

	bool IsAbleToJump() const
	{
		FIceSkatingJumpSettings JumpSettings;
		float Time = Time::GetGameTimeSeconds();
		return (Time - LastJumpTime) > JumpSettings.JumpCooldownPeriod;
	}

	bool HasProjectedGround() const
	{
		return ProjectedGroundHit.bBlockingHit;
	}

	FVector GetProjectedGroundNormal() const property
	{
		FVector Normal = ProjectedGroundHit.Normal;

		// Make sure its not pointing to the side
		Normal = Normal.ConstrainToPlane(Owner.ActorRightVector);

		// Make sure its not pointing backwards
		if (Normal.DotProduct(Owner.ActorForwardVector) < 0.f)
			Normal = Normal.ConstrainToPlane(Owner.ActorForwardVector);

		return Normal;
	}

	FQuat GetRotationFromVelocity(FVector Velocity)
	{
		return Math::MakeQuatFromX(Math::ConstrainVectorToSlope(Velocity, FVector::UpVector, FVector::UpVector));
	}

	/* Events to peek into whats happening in the skating system, for effects mostly */
	UFUNCTION(BlueprintEvent)
	void OnFastChanged(bool bFast) {}

	UFUNCTION(BlueprintEvent)
	void OnStartedSkidding() {}

	UFUNCTION(BlueprintEvent)
	void OnStopSkidding() {}

	void EnableCheering(FName EnableName)
	{
		if (CheerEnableNames.Contains(EnableName))
			return;

		CheerEnableNames.Add(EnableName);
	}

	void DisableCheering(FName EnableName)
	{
		if (!CheerEnableNames.Contains(EnableName))
			return;

		CheerEnableNames.Remove(EnableName);
	}

	void BlockCheering(FName BlockName)
	{
		if (CheerBlockNames.Contains(BlockName))
			return;

		CheerBlockNames.Add(BlockName);
	}

	void UnblockCheering(FName BlockName)
	{
		if (!CheerBlockNames.Contains(BlockName))
			return;

		CheerBlockNames.Remove(BlockName);
	}

	UFUNCTION(BlueprintPure)
	bool IsCheeringEnabled()
	{
		return CheerEnableNames.Num() > 0 && CheerBlockNames.Num() == 0;
	}
}

UFUNCTION(Category = "IceSkating")
void ForceEnterIceSkating(AHazePlayerCharacter Player)
{
	auto IceSkatingComp = UIceSkatingComponent::Get(Player);

	if (IceSkatingComp == nullptr)
		return;

	IceSkatingComp.bForceEnter = true;
}

UFUNCTION(Category = "IceSkating")
bool IsSurfaceIceSkateable(FHitResult Hit)
{
	if (!Hit.bBlockingHit)
		return false;

	// If it either has the tag IceSkateable
	if (Hit.Component != nullptr &&
		Hit.Component.HasTag(ComponentTags::IceSkateable))
	{
		return true;
	}

	// ... or has ice physical material
	// NOTE: Hard-coded to surfacetype42 right now, fix somehow??
	UPhysicalMaterial PhysMaterial = Hit.PhysMaterial;

	if (PhysMaterial != nullptr &&
		PhysMaterial.SurfaceType == EPhysicalSurface::SurfaceType42)
	{
		return true;
	}

	return false;
}

UFUNCTION(Category = "IceSkating")
void EnableIceSkatingCheerForLevel()
{
	for(auto Player : Game::Players)
	{
		auto SkateComp = UIceSkatingComponent::Get(Player);
		if (SkateComp == nullptr)
			continue;

		SkateComp.EnableCheering(n"Level");
	}
}

UFUNCTION(Category = "IceSkating")
void DisableIceSkatingCheerForLevel()
{
	for(auto Player : Game::Players)
	{
		auto SkateComp = UIceSkatingComponent::Get(Player);
		if (SkateComp == nullptr)
			continue;

		SkateComp.DisableCheering(n"Level");
	}
}

UFUNCTION(Category = "IceSkating", BlueprintPure)
bool IsIceSkatingCheeringEnabled(AHazePlayerCharacter Player)
{
	auto SkateComp = UIceSkatingComponent::Get(Player);
	if (SkateComp == nullptr)
		return false;

	return SkateComp.IsCheeringEnabled();
}