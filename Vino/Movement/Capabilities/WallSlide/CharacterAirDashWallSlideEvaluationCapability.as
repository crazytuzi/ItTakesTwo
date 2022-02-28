
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideSettings;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;
import Vino.Movement.Capabilities.WallSlide.WallCheckFunctions;
import Vino.Movement.Dash.CharacterDashSettings;
import Peanuts.Movement.GroundTraceFunctions;

class UCharacterAirDashWallSlideEvaluationsCapability : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::WallSlideEvaluation);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 49;

	UHazeMovementComponent MoveComp;
	UCharacterWallSlideComponent WallData;

	FCharacterWallSlideSettings Settings;
	FWallSlideChecker Checker;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		ensure(MoveComp != nullptr);

		WallData = UCharacterWallSlideComponent::GetOrCreate(Owner);

		Checker.MoveComp = MoveComp;
		Checker.WallDataComp = WallData;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(DashTags::AirDashing))
			return EHazeNetworkActivation::DontActivate;

		if (WallData.WallSlidingIsDisabled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		SetMutuallyExclusive(MovementSystemTags::WallSlideEvaluation, true);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (WallData.WallSlidingIsDisabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (WallData.WantedStartType != EWallSlideStartType::Dash && !IsActioning(DashTags::AirDashing))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Parans)
	{
		SetMutuallyExclusive(MovementSystemTags::WallSlideEvaluation, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!WallData.ShouldSlide())
		{
			Checker.bDebugActive = IsDebugActive();

			// Check for impact.
			FHazeHitResult WallHit;
			if (TraceAndCheckWall(WallHit))
				WallData.SetSlidingTarget(WallHit, true);
		}
	}
	
	bool TraceAndCheckWall(FHazeHitResult& OutWallHit) const
	{
		// Check Input or velocity towards wall
		const FVector HorizontalVelocity = MoveComp.PreviousVelocity.ConstrainToPlane(MoveComp.WorldUp);

		FHazeTraceParams WallTrace;
		WallTrace.InitWithMovementComponent(MoveComp);
		WallTrace.UnmarkToTraceWithOriginOffset();

		// We only use the top part of the capsule to trace with;
		float UsedColliderPercentage = 0.75;
		FVector CapsuleExtents = MoveComp.ActorShapeExtents;

		float TraceCapsuleHeight = CapsuleExtents.Z * UsedColliderPercentage;
		float UnusedHeight = CapsuleExtents.Z - TraceCapsuleHeight;
		WallTrace.SetToCapsule(CapsuleExtents.X, TraceCapsuleHeight);
		WallTrace.From = MoveComp.OwnerLocation + MoveComp.WorldUp * (TraceCapsuleHeight + (UnusedHeight * 2.f));

		float PredictionTime = 0.1;
		WallTrace.To = WallTrace.From + MoveComp.Velocity * PredictionTime;
		WallTrace.DebugDrawTime = Checker.bDebugActive ? 0.f : -1.f;

		FHazeHitResult WallImpact;
		if (!WallTrace.Trace(WallImpact))
			return false;

		if (IsHitSurfaceWalkableDefault(WallImpact.FHitResult, MoveComp.WalkableAngle, MoveComp.WorldUp))
			return false;
		
		FHitResult HeightCorrectionData = WallImpact.FHitResult;
		HeightCorrectionData.Location -= MoveComp.WorldUp * (UnusedHeight * 2.f);
		WallImpact.OverrideFHitResult(HeightCorrectionData);

		FVector CheckVecktor = HorizontalVelocity.GetSafeNormal();
		if (CheckVecktor.IsNearlyZero())
			return false;

		FVector WallNormal = WallImpact.ImpactNormal;
		if (CheckVecktor.DotProduct(WallNormal) >= 0.f)
			return false;
		
		// Check if we are infront a solid wall
		FTransform WallHitRotationTransform = Math::ConstructTransformWithCustomRotation(WallImpact.ActorLocation, -WallNormal, MoveComp.WorldUp);
		if (!Checker.IsFrontSolid(WallHitRotationTransform, OutWallHit))
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "" + WallData.DisabledTimer;
	}
}
