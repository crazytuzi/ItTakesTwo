import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Rice.Math.MathStatics;
import Vino.Movement.SplineSlide.SplineSlideTags;

class USplineSlideAirCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(SplineSlideTags::AirMovement);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 120;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;

	FSplineSlideAirSettings DefaultSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"AirJump", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"AirJump", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SplineSlide");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"AirMovement");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			
			if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
				Velocity -= MoveComp.WorldUp * SplineSlideComp.SplineSettings.Air.Gravity * DeltaTime;
			else
				Velocity -= MoveComp.WorldUp * DefaultSettings.Gravity * DeltaTime;

			FVector DeltaMove = Velocity * DeltaTime;
			// No idea why this sets delta with custom vel, but too late to risk changing it.
			FrameMove.ApplyDeltaWithCustomVelocity(DeltaMove, Velocity);

			FVector FacingDirection = Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			if (FacingDirection.IsNearlyZero())
				FacingDirection = Owner.ActorForwardVector;
			MoveComp.SetTargetFacingDirection(FacingDirection, 5.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}
}
