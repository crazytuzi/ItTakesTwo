import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Components.MovementComponent;

class UCharacterProximityEnterGrindingCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::PotentialGrinds);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Enter);
	default CapabilityTags.Add(GrindingCapabilityTags::Proximity);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 110;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UHazeMovementComponent MoveComp;

	FGrindSplineData ProximityGrindSplineData;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{		
		if (IsBlocked())
			return;

		if (IsActive())
			return;

		if (UserGrindComp.HasTargetGrindSpline())
			return;

		if (UserGrindComp.HasActiveGrindSpline())
			return;

		if (MoveComp.IsGrounded())
			EvaluateBestValidSplineGrounded();
		else
			EvaluateBestValidSplineAirbourne();
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!HasControl())
        	return EHazeNetworkActivation::DontActivate;
		
		// We might get false errors in editor since we run ShouldActive without running pretick when error checking.
		if (!IsActioning(GrindingActivationEvents::PotentialGrinds))
        	return EHazeNetworkActivation::DontActivate;

		if (ProximityGrindSplineData.GrindSpline == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UHazeSplineComponentBase SplineComp;
		float Distance = 0.f;
		bool bForward = true;
		ProximityGrindSplineData.SystemPosition.BreakData(SplineComp, Distance, bForward);
		
		ActivationParams.AddObject(n"TargetGrindSpline", ProximityGrindSplineData.GrindSpline);
		ActivationParams.AddObject(n"TargetSplineComp", SplineComp);
		ActivationParams.AddValue(n"TargetSplineDistance", Distance);
		if (bForward)
			ActivationParams.AddActionState(n"TargetSplineForward");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(MovementSystemTags::Swinging, this);

		AGrindspline GrindSpline = Cast<AGrindspline>(ActivationParams.GetObject(n"TargetGrindSpline"));
		UHazeSplineComponentBase SplineComp = Cast<UHazeSplineComponentBase>(ActivationParams.GetObject(n"TargetSplineComp"));
		float Distance = ActivationParams.GetValue(n"TargetSplineDistance");
		bool bForward = ActivationParams.GetActionState(n"TargetSplineForward");

		FGrindSplineData GrindSplineData(GrindSpline, SplineComp, Distance, bForward);
		UserGrindComp.UpdateTargetGrindSpline(GrindSplineData);
		UserGrindComp.StartGrinding(UserGrindComp.TargetGrindSplineData.GrindSpline, EGrindAttachReason::Proximity, GetAttributeVector(AttributeVectorNames::MovementDirection));

		float NewCurrentSpeed = FMath::Max(UserGrindComp.CalculateInitialSpeed(UserGrindComp.ActiveGrindSplineData, MoveComp.Velocity), UserGrindComp.DesiredSpeed);
		UserGrindComp.OverrideCurrentSpeed(NewCurrentSpeed);
		
		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrindProximityLandRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrindProximityLandRumble, false, true, NAME_None, 0.6f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Swinging, this);

		ProximityGrindSplineData.Reset();
	}

	void EvaluateBestValidSplineAirbourne()
	{
		/*
			Evaluate all nearby splines and update the spline that you should land on
		*/
		ProximityGrindSplineData.Reset();
		float Distance = BIG_NUMBER;

		for (AGrindspline PotentialGrindSpline : UserGrindComp.ValidNearbyGrindSplines)
		{
			FHazeSplineSystemPosition SystemPosition = PotentialGrindSpline.Spline.GetPositionClosestToWorldLocation(Owner.ActorLocation, true);
			FVector HeightOffset = SystemPosition.WorldUpVector * PotentialGrindSpline.HeightOffset;
			FVector SplineTargetLocation = SystemPosition.WorldLocation + HeightOffset;
			FVector ToClosestPosition = SplineTargetLocation - Owner.ActorLocation;
	
			if (!PotentialGrindSpline.bGrindingAllowed)
				continue;
			
			// Invalid if not allowed by spline
			if (!PotentialGrindSpline.bCanLandOn)
				continue;	

			// Invalid if too far away
			// If you are too far away, test that your velocity will take you through the acceptance range
			float DistanceToClosestPosition = ToClosestPosition.Size();

			float AcceptanceRange = GrindSettings::Proximity.AirbourneAcceptanceRange;
				if (PotentialGrindSpline == UserGrindComp.PreviousActiveGrindSpline)
					if (Player.IsAnyCapabilityActive(GrindingCapabilityTags::Jump))
						AcceptanceRange = GrindSettings::Proximity.AirbourneAcceptanceRangeJumpedFrom;

			if (DistanceToClosestPosition > AcceptanceRange)
			{	
				// Check if you are moving towards the target
				float TowardsTargetDot = ToClosestPosition.DotProduct(MoveComp.Velocity);
				if (TowardsTargetDot <= 0.f)
					continue;

				FVector DeltaMove = MoveComp.Velocity * Owner.ActorDeltaSeconds;
				FVector FuturePosition = Owner.ActorLocation + DeltaMove;
				FVector ToFuturePosition = FuturePosition - Owner.ActorLocation;

				FVector PointOnLine = FMath::ClosestPointOnLine(Owner.ActorLocation, FuturePosition, SplineTargetLocation);
				FVector ToPointOnLine = PointOnLine - SplineTargetLocation;
				if (ToPointOnLine.Size() > AcceptanceRange)
					continue;
			}		

			// Invalid if the splines world up is upside down
			if (MoveComp.WorldUp.DotProduct(SystemPosition.WorldUpVector) < 0.f)
				continue;

			// Invalid if the player is outside of the downwards acceptance angle
			float AngleToClosestPosition = Math::DotToDegrees((-SystemPosition.WorldUpVector).DotProduct(MoveComp.Velocity.GetSafeNormal()));
			if (AngleToClosestPosition > GrindSettings::Proximity.AirbourneDownwardsAcceptanceAngleDeg)
				continue;

			// Invalid if you are close to the start or end of the spline
			// Ignore loops
			if (!PotentialGrindSpline.Spline.IsClosedLoop())
			{
				UHazeSplineComponentBase HazeSplineComp;
				float DistanceAlongSpline = 0.f;
				bool bForward;
				SystemPosition.BreakData(HazeSplineComp, DistanceAlongSpline, bForward);

				if (PotentialGrindSpline.StartConnection.EstablishedConnections.Num() == 0 && FMath::IsNearlyEqual(DistanceAlongSpline, 0.f))
					continue;

				if (PotentialGrindSpline.EndConnection.EstablishedConnections.Num() == 0 && FMath::IsNearlyEqual(DistanceAlongSpline, HazeSplineComp.SplineLength))
					continue;
			}

			if (DistanceToClosestPosition < Distance)
			{
				ProximityGrindSplineData = FGrindSplineData(PotentialGrindSpline, SystemPosition);
				Distance = DistanceToClosestPosition;
			}
		}
	}

	void EvaluateBestValidSplineGrounded()
	{
		/*
			Evaluate all nearby splines and update the spline that you should land on
		*/
		ProximityGrindSplineData.Reset();
		float Distance = BIG_NUMBER;

		for (AGrindspline PotentialGrindSpline : UserGrindComp.ValidNearbyGrindSplines)
		{
			FHazeSplineSystemPosition SystemPosition = PotentialGrindSpline.Spline.GetPositionClosestToWorldLocation(Owner.ActorLocation, true);
			FVector HeightOffset = SystemPosition.WorldUpVector * PotentialGrindSpline.HeightOffset;
			FVector SplineTargetLocation = SystemPosition.WorldLocation + HeightOffset;
			FVector ToClosestPosition = SplineTargetLocation - Owner.ActorLocation;

			// Invalid if not allowed by spline
			if (!PotentialGrindSpline.bCanWalkOn)
				continue;

			if (!PotentialGrindSpline.bGrindingAllowed)
				continue;

			// Invalid if too far away
			float DistanceToClosestPosition = ToClosestPosition.Size();
			if (DistanceToClosestPosition > GrindSettings::Proximity.GroundedAcceptanceRange)
				continue;

			// Invalid if angle between velocity and +/-tangent is too high
			FVector Direction = MoveComp.Velocity.IsNearlyZero() ? Owner.ActorForwardVector : MoveComp.Velocity.GetSafeNormal();
			FVector Tangent = SystemPosition.WorldForwardVector;
			float AngleDifference = Math::DotToDegrees(Tangent.DotProduct(Direction));
			if (AngleDifference > 90.f)
				AngleDifference = 180.f - AngleDifference;

			if (AngleDifference >= GrindSettings::Proximity.GroundedSplinewardsAcceptanceAngleDeg)
				continue;

			// Invalid if you are close to the start or end of the spline
			UHazeSplineComponentBase HazeSplineComp;
			float DistanceAlongSpline = 0.f;
			bool bForward;
			SystemPosition.BreakData(HazeSplineComp, DistanceAlongSpline, bForward);

			if (FMath::IsNearlyEqual(DistanceAlongSpline, HazeSplineComp.SplineLength) || FMath::IsNearlyEqual(DistanceAlongSpline, 0.f))
				continue;

			if (DistanceToClosestPosition < Distance)
			{
				ProximityGrindSplineData = FGrindSplineData(PotentialGrindSpline, SystemPosition);
				Distance = DistanceToClosestPosition;
			}
		}
	}
}
