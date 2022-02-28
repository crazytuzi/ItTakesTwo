import Peanuts.Movement.DefaultDepenetrationSolver;
import Peanuts.Movement.CollisionSolver;

const float StepUpPlatformVerifyOffset = 2.0f;
const float MinMoveAwayDeltaAmount = 0.1f;
const float MinStepUpForwardDistance = 1.5f;

const FStatID STAT_StepUp(n"StepUp");
const FStatID STAT_StepDown(n"StepDown");
const FStatID STAT_EdgeCheck(n"EdgeCheck");

class UDefaultCharacterCollisionSolver : UCollisionSolver
{
	float CalculateDistanceToGroundFromSlopeHit(const FHazeHitResult& SlopeHit) const
	{
		// Double check that the ground immidiately under us is walkable!
		// Otherwise this might be a corner or edge or something that came in the way.

		// Calculate how far down we have to trace to reach a lower part of a ramp this steep. 
		//    Triangles, you know.

		// Think of this but upside down I fucked up
		//                           Ground
		//                             /|
		//                           /  |
		//     Slope of ramp ->    /    |    <- Distance to ground trace down
		//                       /      | 
		//                     /        |
		//     Slope hit ->   -----------
		//                Distance to capsule

		//    tan(slope_angle) = distance_to_trace_down / distance_to_capsule
		//    distance_to_trace_down = distance_to_capsule * tan(slope_angle)
		FVector CapsuleToSlopeHit = SlopeHit.ImpactPoint - SlopeHit.TraceStart;
		float CapsuleToSlopeHitLength = CapsuleToSlopeHit.ConstrainToPlane(ActorState.WorldUp).Size();

		float SlopeAngle = Math::DotToRadians(SlopeHit.Normal.DotProduct(ActorState.WorldUp));
		float DistanceToGround = FMath::Tan(SlopeAngle) * CapsuleToSlopeHitLength;

		return DistanceToGround;
	}

	void ProcessImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FHazeHitResult Impact) const
	{
		// If we hit a wall, we might be able to step up onto it
		//	which will invalidate this hit
		if (ImpactType == EImpactSurfaceType::Wall)
		{
			if (PerformStepUp(SolverState, Impact))
				return;
		}

		SolverState.SetHit(ImpactType, Impact);

		FCollisionRedirectInput Redirect;
		Redirect.Impact = Impact;
		InitializeCharacterRedirect(SolverState, Redirect, ImpactType);

		RedirectImpact(SolverState, ImpactType, Redirect);
	}

	void InitializeCharacterRedirect(FCollisionSolverState& SolverState, FCollisionRedirectInput& Redirect, EImpactSurfaceType ImpactType) const
	{
		const FHazeHitResult& Impact = Redirect.Impact;

		// For walls (non-walkable), the following logic is applied:
		if (ImpactType == EImpactSurfaceType::Wall || ImpactType == EImpactSurfaceType::InvisibleWall)
		{
			if (SolverState.PreviousPhysicsState.GroundedState == EHazeGroundedState::Grounded)
			{
				// If we're on the ground, treat the wall as if its straight,
				//	so that we run along the walkable slope instead of up onto it
				Redirect.Method = EDeltaRedirectMethod::PlaneProject;
				Redirect.RedirectNormal = Impact.Normal.ConstrainToPlane(ActorState.WorldUp).GetSafeNormal();
				SolverState.bVelocityIsDirty = true;

				// If we hit a wall then we want to make sure we don't redirect up the wall.
				if (!SolverState.bLeavingGround && SolverState.RemainingDelta.DotProduct(ActorState.WorldUp) > 0.f)
					SolverState.RemainingDelta = SolverState.RemainingDelta.ConstrainToPlane(ActorState.WorldUp);
			}
			else
			{	
				// Otherwise, we want to fully slide up-and-down the wall (like a slippy slide)
				//	but we want to do a regular plane-projection for the side-to-side movement,
				//	otherwise you 'shoot along' the wall when you collide with it
				Redirect.Method = EDeltaRedirectMethod::PlaneProject_PreserveVerticalLength;
				Redirect.RedirectNormal = Impact.Normal;

				// Additionally, for walls which normal point downwards, we DONT want
				//	to dirtify the velocity, since that will make the character shoot
				//	away from the wall when jumping into it. Instead we want the character
				//	to slide upwards, then fall straight down
				SolverState.bVelocityIsDirty = Impact.Normal.DotProduct(ActorState.WorldUp) > 0.f;
			}
		}
		else if (ImpactType == EImpactSurfaceType::Ground)
		{
			// When hitting the ground WHILE grounded, fully redirect delta with the slope
			//	method to preserve directionality
			// But when LANDING on ground, this will make the character shoot forward due to
			//	high downwards speed, so just plane project
			if (SolverState.PreviousPhysicsState.GroundedState == EHazeGroundedState::Grounded)
				Redirect.Method = EDeltaRedirectMethod::PreviousPlaneSlopeProject_PreserveLength;
			else
				Redirect.Method = EDeltaRedirectMethod::PlaneProject;
			
			Redirect.RedirectNormal = Impact.Normal;
			SolverState.bVelocityIsDirty = true;
		}
		else
		{
			if (SolverState.PreviousPhysicsState.GroundedState == EHazeGroundedState::Grounded)
			{
				// If we're on the ground, treat the hit as if we're hitting a straight wall,
				//	so that we run freely from side-to-side
				Redirect.Method = EDeltaRedirectMethod::PlaneProject;
				Redirect.RedirectNormal = Impact.Normal.ConstrainToPlane(ActorState.WorldUp).GetSafeNormal();
				SolverState.bVelocityIsDirty = true;
			}
			else
			{
				// Otherwise, nothing special :^)
				Redirect.Method = EDeltaRedirectMethod::PlaneProject;
				Redirect.RedirectNormal = Impact.Normal;

				// Dont dirtify velocity, because we want to stop, not shoot away to the side
				SolverState.bVelocityIsDirty = false;
			}
		}

	
	}

	bool PerformStepUp(FCollisionSolverState& SolverState, FHazeHitResult WallImpact) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_StepUp);
#endif

		if (ActorState.StepUpAmount <= 0.f)
			return false;

		// We should only trigger a step up we are moving towards the surface horizontally.
		float DirectionOfHit = WallImpact.Normal.DotProduct(SolverState.LastMovedDelta.ConstrainToPlane(ActorState.WorldUp));
		if (DirectionOfHit >= 0.f)
			return false;

		// Step 1: Find the target surface that we are stepping up upon by line tracing!
		// FVector FeetToImpact = (WallImpact.ImpactPoint - (SolverState.CurrentLocation + ShapeTracer.GetLocalColliderBottom(ActorState.WorldUp))).ConstrainToDirection(ActorState.WorldUp);
		// FVector ImpactAtFeet = WallImpact.ImpactPoint - FeetToImpact;

		FVector ImpactHorizontalOffset = (WallImpact.ImpactPoint - SolverState.CurrentLocation).ConstrainToPlane(ActorState.WorldUp);
		float ActorExent = FMath::Abs(ShapeTracer.ShapeRotation.RotateVector(ShapeTracer.CollisionShape.Extent).DotProduct(ActorState.Rotation.ForwardVector));

		float DistanceLeftToEdgeOfCollision = ActorExent - ImpactHorizontalOffset.Size();
		float WalkableAngle = ActorState.WalkableSlopeAngle;
		if (FMath::IsNearlyEqual(WalkableAngle, 90.f))
			WalkableAngle = 89.f;

		float ExtraDownDistance = DistanceLeftToEdgeOfCollision * FMath::Tan(FMath::DegreesToRadians(WalkableAngle));

		// Check if the surface we are moving against is valid to stepup on. (low enough and is valid ground).
		// Trace from the step-up height down to the characters feet, at the edge of the capsule
		// putting the trace inside the wall horizontally.
		FVector SurfaceTraceHorizontalOffset = -WallImpact.ImpactNormal.ConstrainToPlane(ActorState.WorldUp).GetSafeNormal() * (ActorExent + StepUpPlatformVerifyOffset);
		FVector EndTraceLocation = SolverState.CurrentLocation + ShapeTracer.GetLocalColliderBottom(ActorState.WorldUp) + SurfaceTraceHorizontalOffset;
		FVector StartTraceLocation = EndTraceLocation + ActorState.WorldUp * ActorState.StepUpAmount;
		EndTraceLocation += -ActorState.WorldUp * ExtraDownDistance;
		
		// Do the dang trace
		FHazeHitResult TopHit;
		FVector Padding = -ActorState.WorldUp * 10.f;
		bool bHeightIsValid = false;
		bool bSurfaceIsValid = false;
		bool bNoHit = true;

		if (ShapeTracer.LineTest(StartTraceLocation, EndTraceLocation  + Padding, TopHit))
		{
			bNoHit = false;

			// If the hit was start penetrating there was not enough room.

			if (TopHit.bStartPenetrating)
			{
				bHeightIsValid = false;
			}
			else
			{
				bHeightIsValid = true;

				EImpactSurfaceType ImpactType = GetSurfaceTypeFromHit(TopHit);
				if (ImpactType == EImpactSurfaceType::Ground)
					bSurfaceIsValid = true;
			}

			if (!bSurfaceIsValid || !bHeightIsValid)
				return false;
		}

#if EDITOR
		DebugComp.LogStepUpSurfaceCheck(WallImpact.FHitResult, StartTraceLocation, EndTraceLocation, TopHit.FHitResult, bHeightIsValid, bSurfaceIsValid);
#endif

		// Step 2: Do the actual step up
		FCollisionSolverState OldState = SolverState;
		const FVector StepUpVector = ActorState.WorldUp * ActorState.StepUpAmount;

		// Sweep upwards first!
		FHazeHitResult UpHit;
		ShapeTracer.CollisionSweep(SolverState.CurrentLocation, SolverState.CurrentLocation + StepUpVector, UpHit);
		const FVector ActualStepUpVector = StepUpVector * UpHit.Time;
		SolverState.CurrentLocation += ActualStepUpVector;
		
		// Then sweep forwards
		FHazeHitResult ForwardHit;
		float IterationTime = CalculateIterationTimeFromDistance(SolverState, ShapeTracer.CollisionShape.Extent.X * 0.5f);
		if (SweepAndMove(SolverState, IterationTime, ForwardHit, false))
		{
			if (FMath::IsNearlyZero(SolverState.LastMovedDelta.Size(), MinStepUpForwardDistance))
			{
				SolverState = OldState;
				return false;
			}

			EImpactSurfaceType SurfaceType = GetSurfaceTypeFromHit(ForwardHit);
			SolverState.SetHit(SurfaceType, ForwardHit);

			// If we hit ground with the forward sweep, the down-sweep is not necessary!
			if (SurfaceType == EImpactSurfaceType::Ground)
			{
#if EDITOR
				DebugComp.LogStepUp(OldState.CurrentLocation, SolverState.CurrentLocation, ActualStepUpVector, true, ForwardHit.FHitResult);
#endif
				return true;
			}
		}

		// Then sweep downwards
		bool bStepUpIsValid = false;
		FVector SafetyDistance = ActorState.WorldUp * 5.f;
		FHazeHitResult DownHit;
		if (ShapeTracer.CollisionSweep(SolverState.CurrentLocation, SolverState.CurrentLocation - ActualStepUpVector - SafetyDistance, DownHit))
		{
			SolverState.CurrentLocation = DownHit.ActorLocation + GetPullbackAmount(DownHit, EImpactSurfaceType::Ground);
			
			// If we succeed with the down-sweep, we always regard it as a valid step-up
			//	since if the forward-delta is small, you will most likely do a couple of intermediate steps where you
			//	step onto the corner of the capsule, which will normally be considered invalid.

			//	Target surface (step 1)
			//			|  |			  |
			//			|  |			  |
			//			|  \			  /
			//			v	\			 /
			//	-------------\  <-- corner hit
			//				|  --------
			//				|	 
			//				|
			//				|

			if (TopHit.bBlockingHit)
			{
				SolverState.SetHit(EImpactSurfaceType::Ground, TopHit);
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				bStepUpIsValid = true;
			}
			else
			{
				if (IsHitSurfaceWalkable(SolverState, DownHit))
				{
					SolverState.SetHit(EImpactSurfaceType::Ground, TopHit);
					SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
					bStepUpIsValid = true;
				}				
			}
		}

#if EDITOR
		DebugComp.LogStepUp(OldState.CurrentLocation, SolverState.CurrentLocation, ActualStepUpVector, bStepUpIsValid, DownHit.FHitResult);
#endif

		// If the step up failed for some reason, restore the pre-step-up state since we moved it
		if (!bStepUpIsValid)
			SolverState = OldState;

		return bStepUpIsValid;
	}

	bool IsMovingAwayFromSurface(FCollisionSolverState SolverState, FHazeHitResult SurfaceHit) const
	{
		return SolverState.LastMovedDelta.DotProduct(SurfaceHit.ImpactNormal) > MinMoveAwayDeltaAmount;
	}

	bool IsEdgeHitGrounded(FCollisionSolverState SolverState, FVector HorizontalDeltaFromHit, float TraceDistance, FHazeHitResult Hit, FHazeHitResult& OutGroundHit) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_EdgeCheck);
#endif
#if Editor
		DebugComp.LogEdgeCheckStartData(SolverState.CurrentLocation, HorizontalDeltaFromHit, Hit);
#endif
		bool bOutputGrounded = false;

		FVector TraceVector = -ActorState.WorldUp * TraceDistance;

		//Check whats direcly below the shape.
		FMovementQueryLineParams LineTraceParams;
		LineTraceParams.From = SolverState.CurrentLocation + ShapeTracer.GetLocalColliderBottom(ActorState.WorldUp);
		LineTraceParams.To = LineTraceParams.From + TraceVector;
		if (ShapeTracer.LineTest(LineTraceParams, OutGroundHit))
		{
			bOutputGrounded = IsHitSurfaceWalkable(SolverState, OutGroundHit);
		}

		if (!bOutputGrounded)
		{
			FMovementQueryParams ShapeTraceParams;
	
			// if miss or grounded check fails, check what is directly on the other side of the shape from the hit.
			float ShapeWidth = FMath::Abs(ShapeTracer.ShapeRotation.RotateVector(ShapeTracer.CollisionShape.Extent).DotProduct(ActorState.Rotation.ForwardVector));
			float ColliderBeyondImpactPoint = (ShapeWidth - HorizontalDeltaFromHit.Size()) + 0.1f; // Add nudge to add a little buffer from current collision.
			ShapeTraceParams.From = SolverState.CurrentLocation + HorizontalDeltaFromHit.SafeNormal * ColliderBeyondImpactPoint;
			ShapeTraceParams.To = ShapeTraceParams.From + TraceVector;

			if (ShapeTracer.CollisionSweep(ShapeTraceParams, OutGroundHit))
			{
				if (OutGroundHit.bStartPenetrating)
				{
					if (Hit.Component.HasTag(ComponentTags::Walkable))
						bOutputGrounded = true;
				}
				else
					bOutputGrounded = IsHitSurfaceWalkable(SolverState, OutGroundHit);

				// Since we could have a hit a edge we want to make sure we get straight surface results.
				FHitResult ConvertedParams = OutGroundHit.FHitResult;
				ConvertedParams.Normal = ConvertedParams.ImpactNormal;
				OutGroundHit.OverrideFHitResult(ConvertedParams);
			}
#if Editor
			DebugComp.LogEdgeCheck(false, bOutputGrounded, LineTraceParams, ShapeTraceParams, OutGroundHit);
#endif
		}
#if Editor
		else
			DebugComp.LogEdgeCheck(true, false, LineTraceParams, FMovementQueryParams(), OutGroundHit);
#endif

		return bOutputGrounded;
	}

	void PerformStepDown(FCollisionSolverState& SolverState, float StepDownAmount) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_StepDown);
#endif

		ensure(StepDownAmount > 0.f);

		const FVector StartLocation = SolverState.CurrentLocation;

		const FVector TraceVector = -ActorState.WorldUp * FMath::Max(2.f, StepDownAmount);

		FMovementQueryParams ShapeTraceParams;
		ShapeTraceParams.From = SolverState.CurrentLocation;
		ShapeTraceParams.To = SolverState.CurrentLocation + TraceVector;

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
		FHazeHitResult ShapeHit;
		FHazeHitResult ExtraGroundTraceHit;

		bool bIsGrounded = false;

		if (ShapeTracer.CollisionSweep(ShapeTraceParams, ShapeHit))
		{
			// We want to do additional linetraces to see what surface is directly below the capsule,
			//	since, from the step downs' perspective, thats the target surface we're actually stepping down onto
			// We want to use that surface instead to do redirects and such, so you dont get "sucked down" when hitting
			//	the edge of platforms and so on.

			FVector HitToCurrHorizontal = SolverState.CurrentLocation - ShapeHit.ImpactPoint;
			HitToCurrHorizontal = HitToCurrHorizontal.ConstrainToPlane(ActorState.WorldUp);

			bool ShapeHitWalkable = IsHitSurfaceWalkable(SolverState, ShapeHit);
			if (ShapeHitWalkable)
			{
				// If the hit was walkable, triangulate downwards where the slope _should_ be below the capsule,
				//	and line-trace there.
				// If we dont do this, grounded state will break when standing on very steep surfaces with a low step-down height.
				if (HitToCurrHorizontal.Size() <= ShapeTracer.CollisionShape.Extent.X * 0.3f)
				{
					SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				}
				else
				{
					float DistanceToGround = CalculateDistanceToGroundFromSlopeHit(ShapeHit);
					if (IsEdgeHitGrounded(SolverState, HitToCurrHorizontal, FMath::Max(DistanceToGround, StepDownAmount), ShapeHit, ExtraGroundTraceHit))
						SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				}
			}
			else
			{
				// Otherwise, we might be on the edge of a platform, so just line-trace downwards with the step-down amount
				//	to see if we're currently stepping down onto a surface below us.
				if (HitToCurrHorizontal.Size() > ShapeTracer.CollisionShape.Extent.X * 0.1f)
				{
					if (IsEdgeHitGrounded(SolverState, HitToCurrHorizontal, StepDownAmount, ShapeHit, ExtraGroundTraceHit))
						SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				}
			}

			SolverState.CurrentLocation = ShapeHit.ActorLocation + GetPullbackAmount(ShapeHit, EImpactSurfaceType::Ground);
			
			if (ExtraGroundTraceHit.bBlockingHit && !ExtraGroundTraceHit.bStartPenetrating)
				SolverState.SetHit(EImpactSurfaceType::Ground, ExtraGroundTraceHit);
			else
				SolverState.SetHit(EImpactSurfaceType::Ground, ShapeHit);
		}
		else
		{
			SolverState.SetHit(EImpactSurfaceType::Ground, ShapeHit);
		}

#if EDITOR
		DebugComp.LogStepDown(StartLocation, SolverState.CurrentLocation, TraceVector, bIsGrounded, ExtraGroundTraceHit.FHitResult, ShapeHit.FHitResult);
#endif
	}

	void UpdateGroundedState(FCollisionSolverState& SolverState) const override
	{
		// If we have a stepdown then we let the stepdown determine if we are grounded.
		if (ActorState.StepDownAmount > 0.f)
		{
			PerformStepDown(SolverState, ActorState.StepDownAmount);
			return;
		}

#if TEST
		FScopeCycleCounter Counter(STAT_UpdateGroundedState);
#endif

		const FVector StartLocation = SolverState.CurrentLocation;

		const FVector TraceVector = -ActorState.WorldUp * 2.f;

		FMovementQueryParams ShapeTraceParams;
		ShapeTraceParams.From = SolverState.CurrentLocation;
		ShapeTraceParams.To = SolverState.CurrentLocation + TraceVector;

		// We are airbone until proven otherwise!		
		FHazeHitResult ShapeHit;
		FHazeHitResult ExtraGroundTraceHit;

		bool bIsGrounded = false;

		if (ShapeTracer.CollisionSweep(ShapeTraceParams, ShapeHit))
		{
			FRotator ShapeRotation = ShapeTracer.ShapeRotation.Rotator();

			if (IsHitSurfaceWalkable(SolverState, ShapeHit))
			{
				FVector ImpactToCurrLocationHorizontal = SolverState.CurrentLocation - ShapeHit.ImpactPoint;
				ImpactToCurrLocationHorizontal = ImpactToCurrLocationHorizontal.ConstrainToPlane(ActorState.WorldUp);
				if (ImpactToCurrLocationHorizontal.Size() > ShapeTracer.CollisionShape.Extent.X * 0.3f)
				{
					float DistanceToGround = CalculateDistanceToGroundFromSlopeHit(ShapeHit);
					bIsGrounded = IsEdgeHitGrounded(SolverState, ImpactToCurrLocationHorizontal, DistanceToGround, ShapeHit, ExtraGroundTraceHit);
				}
				else
				{
					if (!IsMovingAwayFromSurface(SolverState, ShapeHit))
						bIsGrounded = true;
				}
			}

			if (bIsGrounded)
			{
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;

				if (ExtraGroundTraceHit.bBlockingHit && !ExtraGroundTraceHit.bStartPenetrating)
					SolverState.SetHit(EImpactSurfaceType::Ground, ExtraGroundTraceHit);
				else
					SolverState.SetHit(EImpactSurfaceType::Ground, ShapeHit);
			}
		}		
		else
		{
			SolverState.SetHit(EImpactSurfaceType::Ground, ShapeHit);
		}

#if EDITOR
		DebugComp.LogStepDown(StartLocation, SolverState.CurrentLocation, TraceVector, bIsGrounded, ExtraGroundTraceHit.FHitResult, ShapeHit.FHitResult);
#endif
	}

	float CalculateIterationTimeFromDistance(const FCollisionSolverState& SolverState, float Distance) const
	{
		const float RemainingDistance = SolverState.RemainingDelta.Size();

		if (RemainingDistance > Distance)
		{
			float DistancePercentage = Distance / RemainingDistance;
			float IterationDistanceTime = SolverState.RemainingTime * DistancePercentage;

			return FMath::Min(SolverState.RemainingTime, IterationDistanceTime);
		}

		return SolverState.RemainingTime;
	}

	void PostAllIterations(FCollisionSolverState& SolverState) const override
	{
		// If the last iteration was in depenetration then we need to check if we need to do a step down
		// or just update our grounded state.
		if (SolverState.bLastTraceIncomplete)
			PostSweep(SolverState);
	}

};
