import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.SplineLock.SplineLockComponent;
import Rice.Math.MathStatics;

class UCharacterGrindingJumpCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Jump);
	default CapabilityTags.Add(GrindingCapabilityTags::GrindMoveAction);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 115;

	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 115);

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	USplineLockComponent SplineLockComp;
	
	FGrindSplineData JumpSplineData;
	bool bLockToSpline = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{		
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.ActiveGrindSpline.bCanJump)
       		return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.SplinePosition.WorldUpVector.DotProduct(MoveComp.WorldUp) < 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump))
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);

		// Copy the spline data and release from the active spline
		JumpSplineData = UserGrindComp.ActiveGrindSplineData;
		FHazeSplineSystemPosition ForwardPosition = JumpSplineData.SystemPosition;
		
		FHazeSplineSystemPosition TestPosition = JumpSplineData.SystemPosition;
		FHazeSplineSystemPosition BiggestDifferencePosition = JumpSplineData.SystemPosition;
		const float ForwardDistance = UserGrindComp.CurrentSpeed;
		const int Steps = 10;
		const float DistancePerStep = ForwardDistance / Steps;

		const FVector JumpStartLocation = Owner.ActorLocation;
		float BiggestHeightDifference = 0.f;

		// Get the highest point along the forward distance
		for (int Index = 0; Index < Steps; Index++)
		{
			// Move the test position forwards
			float Remainder = 0.f;
			TestPosition.Move(DistancePerStep, Remainder);
			if (IsDebugActive())
				System::DrawDebugSphere(TestPosition.WorldLocation, 25.f, 8, FLinearColor::Green, 3.f, 3.f);

			// Calculate the height of the point relative to the start position, and update HighestHeight
			FVector ToNewPosition = TestPosition.WorldLocation - JumpStartLocation;
			float HeightDifference = ToNewPosition.DotProduct(MoveComp.WorldUp);

			if (FMath::Abs(HeightDifference) > FMath::Abs(BiggestHeightDifference))
			{
				BiggestDifferencePosition = TestPosition;
				BiggestHeightDifference = HeightDifference;
			}

			// If you have a remainder, it means you reached and overshot the end of the spline.
			if (Remainder > 0.f)
				break;
		}

		// Calculate an angle between the player and the highest point's location
		float AngleBetween = 0.f;
		FVector ToBiggestDifferencePosition = BiggestDifferencePosition.WorldLocation - JumpStartLocation;
		if (!FMath::IsNearlyEqual(BiggestDifferencePosition.DistanceAlongSpline, JumpSplineData.SystemPosition.DistanceAlongSpline, DistancePerStep - 1.f))
		{
			FVector DirectionToHighest = ToBiggestDifferencePosition.GetSafeNormal();

			// Create a new axis instead of using the splines right vector because banked grind splines can taint the result
			FVector ConstrainPlaneAxis = MoveComp.WorldUp.CrossProduct(JumpSplineData.SystemPosition.WorldForwardVector);
			DirectionToHighest = DirectionToHighest.ConstrainToPlane(ConstrainPlaneAxis);
			DirectionToHighest.Normalize();

			FVector FlattenedForward = JumpSplineData.SystemPosition.WorldRightVector.CrossProduct(MoveComp.WorldUp).SafeNormal;
			AngleBetween = DirectionToHighest.AngularDistance(FlattenedForward) * RAD_TO_DEG;
			AngleBetween *= FMath::Sign(MoveComp.WorldUp.DotProduct(ToBiggestDifferencePosition));

			if (IsDebugActive())
				System::DrawDebugLine(JumpStartLocation, BiggestDifferencePosition.WorldLocation, FLinearColor::LucBlue, 3.f, 5.f);
		}

		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(UserGrindComp.SpeedSettings.BasicSettings.DesiredMaximum * 1.2f);

		if (UserGrindComp.ShouldLockToSpline(GetAttributeVector(AttributeVectorNames::MovementDirection)))
		{
			UserGrindComp.LockHorizontallyToActiveSpline();
			MoveComp.Velocity = HorizontalVelocity;
		}
		else
		{
			FVector VerticalVelocity = MoveComp.Velocity - HorizontalVelocity;

			FVector TangentRight = UserGrindComp.SplinePosition.WorldRightVector;
			TangentRight.Z = 0.f;
			TangentRight.Normalize();

			FVector HorizontalImpulse = (GetAttributeVector(AttributeVectorNames::MovementDirection) * 500.f).ConstrainToDirection(TangentRight);
			HorizontalVelocity += HorizontalImpulse;
			MoveComp.Velocity = VerticalVelocity + HorizontalVelocity;
		}

		float JumpImpulse = GrindSettings::Jump.Impulse;
		float JumpImpulseOffset = 0.f;

		float SlopePercentage = FMath::Clamp(AngleBetween / GrindSettings::Jump.ExtraImpulseMaxTestAngle, -1.f, 1.f);
		JumpImpulseOffset = SlopePercentage * GrindSettings::Jump.ExtraImpulse;

		FVector VerticalVelocity = MoveComp.WorldUp * (JumpImpulse + JumpImpulseOffset);

		MoveComp.SetVelocity(HorizontalVelocity + VerticalVelocity);

		UserGrindComp.StartGrindSplineCooldown(UserGrindComp.ActiveGrindSpline);
		UserGrindComp.StartGrindSplineLowPriority(UserGrindComp.ActiveGrindSpline);
		
		UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Jump);
		Player.SetCapabilityActionState(GrindingActivationEvents::GrindJumping, EHazeActionState::Active);

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrindJumpRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrindJumpRumble, false, true, NAME_None, 0.6f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!UserGrindComp.IsSplineLocked())
		{
			if (MoveComp.Velocity.DotProduct(MoveComp.WorldUp) < -MoveComp.ActiveSettings.ActorMaxFallSpeed)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams)
	{
		Owner.UnblockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);
		
		ConsumeAction(GrindingActivationEvents::GrindJumping);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(GrindingCapabilityTags::Jump);
			CalculateFrameMove(FrameMove, DeltaTime);

			MoveCharacter(FrameMove, n"Grind", n"Jump");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}
	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

			FVector VerticalVelocity = MoveComp.WorldUp * MoveComp.WorldUp.DotProduct(MoveComp.Velocity);
			VerticalVelocity -= MoveComp.WorldUp * GrindSettings::Jump.Gravity * MoveComp.JumpSettings.JumpGravityScale * DeltaTime;
			
			FVector HorizontalDelta = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp) * DeltaTime;

			// Update horizontal velocity
			if (UserGrindComp.IsSplineLocked())
			{
				FVector SplineLockTangent = SplineLockComp.Constrainer.CurrentSplineLocation.WorldForwardVector;

				FVector Tangent = SplineLockTangent * FMath::Sign(HorizontalDelta.DotProduct(SplineLockTangent));
				Tangent = Tangent.ConstrainToPlane(MoveComp.WorldUp);
				Tangent.Normalize();

				HorizontalDelta = Tangent * HorizontalDelta.Size();
			}
			else
			{
				float TargetSpeed = MoveComp.HorizontalAirSpeed;
				HorizontalDelta = GetHorizontalAirDeltaMovement(DeltaTime, MoveInput, TargetSpeed);
			}

			FrameMove.ApplyDelta(HorizontalDelta);
			FVector FacingDirection = Owner.ActorForwardVector;
			if (!HorizontalDelta.IsNearlyZero())
				MoveComp.SetTargetFacingDirection(HorizontalDelta.GetSafeNormal());
			FrameMove.ApplyVelocity(VerticalVelocity);
			FrameMove.OverrideStepDownHeight(0.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}

	UFUNCTION()
    FVector GetHorizontalAirDeltaMovement(float DeltaTime, FVector Input, float MoveSpeed)const
    {    
        const FVector ForwardVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
        const FVector InputVector = Input.ConstrainToPlane(MoveComp.WorldUp);
        if(!InputVector.IsNearlyZero())
        {
            const FVector CurrentForwardVelocityDir = ForwardVelocity.GetSafeNormal();
            const float CorrectInputAmount = (InputVector.DotProduct(CurrentForwardVelocityDir) + 1) * 0.5f;           
        
            const FVector WorstInputVelocity = InputVector * MoveSpeed;
            const FVector BestInputVelocity = InputVector * FMath::Max(MoveSpeed, ForwardVelocity.Size());

            const FVector TargetVelocity = FMath::Lerp(WorstInputVelocity, BestInputVelocity, CorrectInputAmount);
			// 2500.f
            return FMath::VInterpConstantTo(ForwardVelocity, TargetVelocity, DeltaTime, 6000.f) * DeltaTime; 
        }
        else
        {
			return ForwardVelocity * DeltaTime;
        }          
    }
}
