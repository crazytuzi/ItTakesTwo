import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.SplineSlide.SplineSlideRampJump;

class USplineSlideRampJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	default CapabilityTags.Add(MovementSystemTags::Jump);
	default CapabilityTags.Add(SplineSlideTags::Jump);

	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 60;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;

	float DistanceAlongSpline;
	FVector SplineRight;
	float Gravity = 0.f;

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

    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkActivation::DontActivate;

		if (SplineSlideComp.ActiveRampJumps.Num() == 0)
       		return EHazeNetworkActivation::DontActivate;

		if (WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (MoveComp.IsAirborne())
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
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"RampJump", SplineSlideComp.ActiveRampJumps[0]);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"AirJump", this);

		if (ActivationParams.IsStale())
			return;

		MoveComp.AddImpulse(MoveComp.WorldUp * SplineSlideComp.SplineSettings.RampJump.Impulse);
		Gravity = SplineSlideComp.SplineSettings.RampJump.Gravity;

		ASplineSlideRampJump RampJump = Cast<ASplineSlideRampJump>(ActivationParams.GetObject(n"RampJump"));
		if (RampJump != nullptr)
			RampJump.OnJumpActivated.Broadcast();

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

		FName AnimTag;
		if (MoveComp.GetVelocity().DotProduct(MoveComp.WorldUp) > 0.f)
			AnimTag = FeatureName::Jump;
		else
			AnimTag = FeatureName::AirMovement;

		MoveCharacter(FrameMove, AnimTag);

		CrumbComp.LeaveMovementCrumb();	

		SplineSlideComp.UpdateJumpDestination(Owner.ActorLocation, Owner.ActualVelocity, DistanceAlongSpline);
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

			// Gravity Acceleration - read the settings value in case it has been updated since last tick
			if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
				Gravity = SplineSlideComp.SplineSettings.RampJump.Gravity;				
			Velocity += -MoveComp.WorldUp * Gravity * DeltaTime;

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
}
