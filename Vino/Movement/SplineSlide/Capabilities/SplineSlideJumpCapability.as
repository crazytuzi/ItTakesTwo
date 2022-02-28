import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Rice.Math.MathStatics;
import Vino.Movement.SplineSlide.SplineSlideTags;

class USplineSlideJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	default CapabilityTags.Add(MovementSystemTags::Jump);
	default CapabilityTags.Add(SplineSlideTags::Jump);

	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;

	bool bJumpAllowed = true;
	float DistanceAlongSpline = 0.f;
	FVector SplineRight;

	const float Cooldown = 0.5f;
	float CooldownTracker = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
			bJumpAllowed = SplineSlideComp.ActiveSplineSlideSpline.bAllowJump;

		CooldownTracker -= DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (CooldownTracker > 0.f)
       		return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsWithinJumpGroundedGracePeriod(SplineSlideComp.CoyoteTime))
       		return EHazeNetworkActivation::DontActivate;

		if (!bJumpAllowed)
       		return EHazeNetworkActivation::DontActivate;

		if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
       		return EHazeNetworkActivation::ActivateUsingCrumb;

		if (Player.IsAnyCapabilityActive(SplineSlideTags::AirMovement))
       		return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.UpHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		if (MoveComp.ForwardHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		// If any impulses are applied, cancel the jump
		FVector Impulse = FVector::ZeroVector;
		MoveComp.GetAccumulatedImpulse(Impulse);
		if (!Impulse.IsNearlyZero())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"AirJump", this);
		CooldownTracker = Cooldown;
		
		if (ActivationParams.IsStale())
			return;

		MoveComp.AddImpulse(MoveComp.WorldUp * SplineSlideComp.SplineSettings.Jump.Impulse);

		if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
			SplineSlideComp.ActiveSplineSlideSpline.OnSlideJump.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"AirJump", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SplineSlideJump");
		CalculateFrameMove(FrameMove, DeltaTime);

		FName AnimTag = FeatureName::AirMovement;
		if (ActiveDuration == 0.f)
			AnimTag = FeatureName::Jump;

		SplineSlideComp.UpdateJumpDestination(Owner.ActorLocation, Owner.ActualVelocity, DistanceAlongSpline);
		MoveCharacter(FrameMove, AnimTag);
		CrumbComp.LeaveMovementCrumb();		
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

			if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
			{
				DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
				SplineRight = SplineSlideComp.ActiveSplineSlideSpline.GetSplineRight(DistanceAlongSpline);
			}

			if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
				Velocity += -MoveComp.WorldUp * SplineSlideComp.SplineSettings.Jump.Gravity * DeltaTime;

			FVector LateralVelocity = SplineRight * Velocity.DotProduct(SplineRight);
			FVector NonLateralVelocity = Velocity - LateralVelocity;
			
			// Lateral Acceleration / Drag
			LateralVelocity -= LateralVelocity * SplineSlideComp.SplineSettings.Lateral.DragCoefficient * DeltaTime;
			LateralVelocity += MoveInput.ConstrainToDirection(SplineRight) * SplineSlideComp.SplineSettings.Lateral.Acceleration * DeltaTime;
			LateralVelocity = LateralVelocity.GetClampedToMaxSize(SplineSlideComp.SplineSettings.Lateral.MaximumSpeed);

			Velocity = LateralVelocity + NonLateralVelocity;

			// Spline locking
			FVector DeltaMove = Velocity * DeltaTime;
			if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
			{
				if (SplineSlideComp.ActiveSplineSlideSpline.bLockToSplineWidth)
					SplineSlideComp.ConstrainVelocityToSpline(Velocity, DeltaMove, DeltaTime);
			}

			MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal(), 5.f);

			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideStepUpHeight(0.f);
			FrameMove.ApplyDeltaWithCustomVelocity(DeltaMove, Velocity);
		
			FrameMove.ApplyTargetRotationDelta();	
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);	
		}	
	}

	// Will rotate velocity towards the tangents direction
	FVector GetVelocityRotatedTowardsSplineForward(FVector Velocity, FVector TargetDirection, float DeltaTime)
	{	
		return Math::RotateVectorTowardsAroundAxis(Velocity, TargetDirection, MoveComp.WorldUp, SplineSlideComp.SplineSettings.Jump.TangentRotationRate * DeltaTime);
	}
}
