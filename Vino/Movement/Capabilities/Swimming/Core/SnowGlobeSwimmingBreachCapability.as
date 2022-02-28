import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Rice.Math.MathStatics;

class USnowGlobeSwimmingBreachCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::AboveWater);
	default CapabilityTags.Add(SwimmingTags::Breach);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 108;

	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 200);

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;

	FVector InitialDirectionFlattened;
	float VelocityAngleClamp = 80.f;

	FVector Velocity;

	// UPROPERTY()
	// float MinimumBreachAngle = 35.f;

	bool bDiveTriggered = false;
	bool bAirMovesBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;
	
		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (SwimComp.bIsInWater)
			return EHazeNetworkActivation::DontActivate;

		if (SwimComp.SwimmingState != ESwimmingState::Swimming)
			return EHazeNetworkActivation::DontActivate;

		if (SwimComp.SwimmingSpeedState == ESwimmingSpeedState::Normal)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if(MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if (SwimComp.SwimmingSpeedState == ESwimmingSpeedState::Cruise)
			OutParams.AddActionState(n"ActivatedWhileCruising");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		if (bDiveTriggered)
			MoveComp.SetAnimationToBeRequested(n"SwimmingDive");
		else
			Velocity = MoveComp.Velocity;

		bDiveTriggered = false;

		if (ActivationParams.GetActionState(n"ActivatedWhileCruising"))
			BlockAirMoves();

		SwimComp.SwimmingState = ESwimmingState::Breach;

		// Make sure the speed is at least the minimum allowed
		Velocity = FMath::Max(Velocity.GetSafeNormal() * SwimComp.DesiredSpeed, Velocity);

		InitialDirectionFlattened = (Velocity * FVector(1, 1, 0)).GetSafeNormal();

		if (SwimComp.AudioData[Player].SubmergedBreach != nullptr)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedBreach);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		Player.ClearPointOfInterestByInstigator(this);
		Player.SetCapabilityActionState(n"ResetDolphinCombo", EHazeActionState::Active);

		if (bAirMovesBlocked)
			UnblockAirMoves();

		// If nothing else in the swimming system took over...
		if (SwimComp.SwimmingState == ESwimmingState::Breach)
			SwimComp.SwimmingState = ESwimmingState::Inactive;

		if (SwimComp.SwimmingScore > 0 && !Player.IsAnyCapabilityActive(SwimmingTags::Vortex))
			SwimComp.PlaySplashSound(HazeAkComp, MoveComp.Velocity.Size(), ESplashType::Breach);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		SwimComp.BlockSurfaceDuration = 2.f;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingBreach");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"SwimmingBreach");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{					
			Velocity = Velocity - MoveComp.WorldUp * SwimmingSettings::Breach.Gravity * DeltaTime;
			
			// If freestyle is active, do not turn;
			if (!Player.IsAnyCapabilityActive(n"SwimmingBreachFreestyle"))
				UpdateHorizontalVelocity(DeltaTime);

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepUpHeight(0.f);		
			FrameMove.OverrideStepDownHeight(0.f);

			FVector FacingDirection = Owner.ActorForwardVector;
			if (!Velocity.ConstrainToPlane(MoveComp.WorldUp).IsNearlyZero(20.f))
			{ 
				FacingDirection = Velocity.GetSafeNormal();
			}
			MoveComp.SetTargetFacingDirection(FacingDirection, 6.f);
			FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}	
	}

	void UpdateHorizontalVelocity(float DeltaTime)
	{
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;

		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		if (MoveDirection.DotProduct(HorizontalVelocity.GetSafeNormal()) < 0.f)
		{
			HorizontalVelocity = FMath::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, 1.f);
		}

		// Scale based off of wanted direction and size of your input
		float RotationScale = FMath::Lerp(SwimmingSettings::Breach.MinimumTurnRateScale, 1.f, (1 - FMath::Abs(MoveDirection.DotProduct(HorizontalVelocity.SafeNormal)))) * MoveDirection.Size();
		float RotationRate = SwimmingSettings::Breach.TurnRateDegrees * RotationScale * DeltaTime;

		HorizontalVelocity = Math::RotateVectorTowardsAroundAxis(HorizontalVelocity, MoveDirection, MoveComp.WorldUp, RotationRate);
		Velocity = HorizontalVelocity + VerticalVelocity;
	}

	void BlockAirMoves()
	{
		Owner.BlockCapabilities(MovementSystemTags::AirJump, this);
		Owner.BlockCapabilities(MovementSystemTags::AirDash, this);
		bAirMovesBlocked = true;
	}

	void UnblockAirMoves()
	{
		Owner.UnblockCapabilities(MovementSystemTags::AirJump, this);
		Owner.UnblockCapabilities(MovementSystemTags::AirDash, this);
		bAirMovesBlocked = false;
	}
}
