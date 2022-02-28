import Peanuts.Movement.MovementDebugDataComponent;
import Peanuts.Movement.CollisionData;

const FStatID STAT_SimpleDepenetration(n"SimpleDepenetration");
const FStatID STAT_AdvanvedDepenetration(n"AdvancedDepenetration");

const FStatID STAT_StaticPlatformDepenetration(n"StaticPlatformDepenetration");
const FStatID STAT_PushingPlatformDepenetration(n"PushingPlatformDepenetration");



struct FDefaultDepenetrationSolver
{
#if EDITOR
	UMovementDebugDataComponent DebugComp = nullptr;
#endif


	//Returns if the actor is squished or not.
	FDepenetrationOutput HandleStartPenetrating(FCollisionSolverActorState ActorState, UHazeShapeTracer ShapeTracer, FVector Location, bool bStartedInCollision, FHazeHitResult StartPenHit) const
	{
		/* 	Cases that can lead us to be a stuck in start penetration:
				* Something moved in to the actor - Should only be true for the first iteration, We do additional checks on this to check if should push us or just do a normal depen out of it.
				* We are tracing along a surface, when we get a impact we do a little pullback from it to avoid getting stuck inside for the next trace but when tracing along a surface the current
				method we use is not enough and making the pullback longer makes it effect the actual movement leading to stutters. Solution is to allow the trace to leave the character in penetration
				and then solve the penetration next frame.

				---
				Since scene queries uses different algorithms then direct shape traces that can give us different result our best tool is to use the depenetration result we get back from the scene sweep.
		*/

		if (!ActorState.bDepenetrateOtherMoveComps)
		{
			AHazeActor HitHazeActor = Cast<AHazeActor>(StartPenHit.Actor);
			if (HitHazeActor != nullptr)
			{
				UHazeBaseMovementComponent OtherMoveComp = UHazeBaseMovementComponent::Get(HitHazeActor);
				if (OtherMoveComp != nullptr && OtherMoveComp.bDepenetrateOutOfOtherMovementComponents)
				{
					FDepenetrationOutput Output;
					Output.bValidResult = true;
					Output.DepenetrationDelta = FVector::ZeroVector;
					Output.IgnoreActor = HitHazeActor;
					return Output;
				}
			}
		}

		if (bStartedInCollision)
		{
			//During the first iteration of the trace we can be pushed and squished.
			return StartPenDepenetrate(ActorState, ShapeTracer, Location);
		}
		else
		{
			//here we just do a normal depenetration.
			return Depenetrate(ActorState, ShapeTracer, Location, StartPenHit.Normal * (StartPenHit.PenetrationDepth + 0.5f));
		}
	}

	FDepenetrationOutput Depenetrate(FCollisionSolverActorState ActorState, UHazeShapeTracer ShapeTracer, FVector StartLocation, FHazeHitResult Hit) const
	{
		return Depenetrate(ActorState, ShapeTracer, StartLocation, Hit.Normal * (Hit.PenetrationDepth + 0.01f));
	}

	FDepenetrationOutput Depenetrate(FCollisionSolverActorState ActorState, UHazeShapeTracer ShapeTracer, FVector StartLocation, FVector MTDVector) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_SimpleDepenetration);
#endif

		TArray<FOverlapResult> OverlapCache;

		FDepenetrationOutput Output;
		Output.bValidResult = true;
		FVector CurrentLocation = StartLocation + MTDVector;
		if (!IsOverlapping(CurrentLocation, ActorState, ShapeTracer, OverlapCache))
		{
			// Initial overlap vector worked we can early out.
			Output.DepenetrationDelta = MTDVector;
			return Output;
		}
		
		CurrentLocation = CalculateNonPushingDepenetration(ActorState, CurrentLocation, false, ShapeTracer, OverlapCache);
		Output.DepenetrationDelta = CurrentLocation - StartLocation;

		return Output;
	}

	FDepenetrationOutput StartPenDepenetrate(FCollisionSolverActorState ActorState, UHazeShapeTracer ShapeTracer, FVector Location) const
	{
		TArray<FOverlapResult> OverlapCache;
		if (!IsOverlapping(Location, ActorState, ShapeTracer, OverlapCache))
		{
			//If we are not overlapping just early out.
			FDepenetrationOutput Output;
			Output.bValidResult = true;
			return Output;
		}

		return StartPenDepenetrate(ActorState, ShapeTracer, Location, OverlapCache);
	}

	FDepenetrationOutput StartPenDepenetrate(FCollisionSolverActorState ActorState, UHazeShapeTracer ShapeTracer, FVector Location, TArray<FOverlapResult>& Overlaps) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_AdvanvedDepenetration);
#endif

		FDepenetrationOutput Output;
		Output.bValidResult = true;

		// We first do a normal depenetration resolve, Excluding Primtives that should push us.
		FVector DepenetratedLocation = CalculateNonPushingDepenetration(ActorState, Location, true, ShapeTracer, Overlaps);
		
		// Now if we are overlapping something it should only be something that pushes us.
		bool bPushSquished = false;
		if (Overlaps.Num() > 0)
		{
			FShapeTracerIgnoresRestorePoint TracerRestorePoint(ShapeTracer);

			FVector PushedToLocation = CalculatePushingDepenetration(ActorState, ShapeTracer, DepenetratedLocation, bPushSquished, Overlaps, Output.PushData);
			DepenetratedLocation = PushedToLocation;

			ShapeTracer.RestoreIgnores(TracerRestorePoint);
		}

		Output.bIsSquished = bPushSquished;
		Output.DepenetrationDelta = DepenetratedLocation - Location;

		return Output;
	}

	bool IsOverlapping(FVector LocationToCheck, FCollisionSolverActorState ActorState, const UHazeShapeTracer ShapeTracer, TArray<FOverlapResult>& Overlaps) const
	{
		FMovementQueryParams Params;
		Params.From = LocationToCheck;
		Params.To = Params.From;
		Params.ShapeInflation = FVector::OneVector;
		
		return ShapeTracer.Overlap(Params, Overlaps);
	}

	bool PrimitiveWantsToPush(UPrimitiveComponent ComponentToValidate, const FVector CurrentLocation, FCollisionSolverActorState ActorState, FMTDResult MTDResult) const
	{
		// Check if the primitive can move.
		if (ComponentToValidate.Mobility != EComponentMobility::Movable)
			return false;

		// Check if the primtive is moving.
		FVector PrimitiveVel = ComponentToValidate.GetPhysicsLinearVelocity();
		FVector PrimitiveAngularVel = ComponentToValidate.GetPhysicsAngularVelocityInDegrees();
		if (PrimitiveVel.IsNearlyZero() && PrimitiveAngularVel.IsNearlyZero())
			return false;

		// If the normal MTD is straight in worldup then we might have just been nicted by it and don't want to be pushed by it.
		// Might need a distance check aswell.
		if (MTDResult.Direction.DotProduct(ActorState.WorldUp) > 0.995f)
			return false;

		// We do not handle being "pushed" by the MoveWithComponent here, we have a seperate pass for that.
		// Test for now to allow the actor to do normal depenetration out of it, but should probably do it so the depenetration pass ignores it entirely.
		if (ActorState.CurrentFloor != nullptr)
		{
			if (ActorState.CurrentFloor == ComponentToValidate)
				return false;

			if (ComponentToValidate.IsAttachedTo(ActorState.CurrentFloor) || ActorState.CurrentFloor.IsAttachedTo(ComponentToValidate))
				return false;
		}

		FVector ClosestPoint;
		ComponentToValidate.GetClosestPointOnCollision(CurrentLocation, ClosestPoint);
		FVector DirectionFromClosestPoint = (CurrentLocation - ClosestPoint).GetSafeNormal();
		FVector VelocityAtImpactPoint = ComponentToValidate.GetPhysicsLinearVelocityAtPoint(ClosestPoint);
		
		if (!VelocityAtImpactPoint.IsNearlyZero())
		{
			// check if what is pushing us is on the correct side to push (might tunnel if the platforms moves with highspeed and/or we have a low frame rate)
			// Just comparing the MTDdirection versus the pushdirection for now, if tunneling becomes a problem then we might want to make this more advanced.
			FVector DirectionToPush = VelocityAtImpactPoint.GetSafeNormal();

			if (DirectionToPush.DotProduct(DirectionFromClosestPoint) > 0.f)
			{
				return true;
			}
		}

		return false;
	}

	FVector CalculateNonPushingDepenetration(FCollisionSolverActorState ActorState, FVector StartLocation, bool bAllowPushing, const UHazeShapeTracer ShapeTracer, TArray<FOverlapResult>& Overlaps) const
	{
		/*
			Iterate over all currently overalapping primitives and and move out of them one at a time.
		*/

#if TEST
		FScopeCycleCounter Counter(STAT_StaticPlatformDepenetration);
#endif

		FVector CurrentLocation = StartLocation;
		
		FMovementQueryParams OverlapQuery;

		int LoopCount = 4; // Escape Infinite loops.
		bool bOverlapsAreDirty = true;

		while (bOverlapsAreDirty && (LoopCount-- > 0))
		{
			bOverlapsAreDirty = false;

			OverlapQuery.From = CurrentLocation;

			for (const FOverlapResult& Overlap : Overlaps)
			{
				UPrimitiveComponent OverlappingPrimitive = Overlap.Component;
				if (OverlappingPrimitive.IsSimulatingPhysics())
				{
					// Should make the trace not pick this up at all
					continue;
				}

				const FVector ColliderLocation = ShapeTracer.ColliderOffset + CurrentLocation;
				// Find MTD Vector for this Primtive
				FMTDResult MTD;
				if (!Trace::ComputeMTD(Overlap, MTD, ShapeTracer.CollisionShape, ColliderLocation, ShapeTracer.ShapeRotation))
				{
#if EDITOR
					DebugComp.LogFailedMTDDepenetration(Overlap.Component, ShapeTracer.CollisionShape, ColliderLocation, ShapeTracer.ShapeRotation.Rotator());
#endif
					continue;
				}

				// Check if we should be pushed by the primtive if we would we ignore it and resolve it after we are done with the none pushing primitives.
				if (bAllowPushing && PrimitiveWantsToPush(OverlappingPrimitive, CurrentLocation, ActorState, MTD))
				{
				 	continue;
				}

				// Now we actually depenetrate the primitive.
				const float ExtraPullback = 0.125f; // Add a little bit of extra distance to avoid touching what we just depentrated.

				const FVector Depenetration = MTD.Direction * (MTD.Distance + ExtraPullback);
				CurrentLocation += Depenetration; 
				bOverlapsAreDirty = true;
			}

			if (bOverlapsAreDirty)
				bOverlapsAreDirty = IsOverlapping(CurrentLocation, ActorState, ShapeTracer, Overlaps);
		}

		return CurrentLocation;
	}

	FVector CalculatePushingDepenetration(FCollisionSolverActorState ActorState, UHazeShapeTracer ShapeTracer, FVector PushStartLocation, bool& bOutIsSquished, TArray<FOverlapResult>& Overlaps, FPlatformPushData& OutPushData) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_PushingPlatformDepenetration);
#endif

		TArray<UPrimitiveComponent> ValidPushingPrimitives;
		// Validate the hits
		for (const FOverlapResult& Overlap : Overlaps)
		{
			UPrimitiveComponent OverlappingPrimitive = Overlap.Component;

			if (OverlappingPrimitive.IsSimulatingPhysics())
			{
				continue;
			}
			
			const FVector ColliderLocation = ShapeTracer.ColliderOffset + PushStartLocation;
			// Find MTD Vector for this Primtive
			FMTDResult MTD;
			if (!Trace::ComputeMTD(Overlap, MTD, ShapeTracer.CollisionShape, ColliderLocation, ActorState.Rotation))
			{
#if EDITOR
				DebugComp.LogFailedMTDDepenetration(Overlap.Component, ShapeTracer.CollisionShape, ColliderLocation, ShapeTracer.ShapeRotation.Rotator());
#endif
				// False means we got a false positive earlier and we are not really overlapping this Primitive.'
				continue;
			}

			if (!PrimitiveWantsToPush(OverlappingPrimitive, PushStartLocation, ActorState, MTD))
				continue;
			
			ValidPushingPrimitives.AddUnique(OverlappingPrimitive);
		}

		// If all hits where invalid we can just early out.
		if (ValidPushingPrimitives.Num() == 0)
			return PushStartLocation;
		
		// Now we want to combine all pushes to find what direction we should depenetrate the actor in and how far we need to trace.
		// we also check for squishing early outs.
		FVector CurrentPushDirection = FVector::ZeroVector;
		float BiggestColliderRadius = 0.f;

		for (int iPusher = 0; iPusher < ValidPushingPrimitives.Num(); ++iPusher)
		{
			UPrimitiveComponent FirstPusher = ValidPushingPrimitives[iPusher];
			FVector FirstPushDirection = FirstPusher.GetPhysicsLinearVelocityAtPoint(PushStartLocation).GetSafeNormal();

			for (int iOtherPusher = iPusher + 1; iOtherPusher < ValidPushingPrimitives.Num(); ++iOtherPusher)
			{
				// If we have two primitives pushing the actor towards eachother then we squish the actor.
				// This will probably need to be fixed to make some leeway for how the actor is overlapping, allowing it to be nudged in a direction.
				UPrimitiveComponent& OtherPusher = ValidPushingPrimitives[iOtherPusher];
				FVector OtherPushDirection = OtherPusher.GetPhysicsLinearVelocityAtPoint(PushStartLocation).GetSafeNormal();;
				if (FirstPushDirection.DotProduct(OtherPushDirection) < 0.f)
				{
					bOutIsSquished = true;
					return PushStartLocation;
				}
			}

			CurrentPushDirection += FirstPushDirection;
			BiggestColliderRadius = FMath::Max(BiggestColliderRadius, FirstPusher.GetBoundingBoxExtents().Size());
		}

		if (CurrentPushDirection.IsNearlyZero())
			return PushStartLocation;
			
		//we now trace backwards to find the position closest position to what is pushing us.
		CurrentPushDirection.Normalize();

		// We trace backwards towards from a distance where we know we wont overlap any of our current overlapping primitives.
		// We are trying to find one of the pushing primtives again to find the location it wants to push us.
		const float HowFarToTraceFrom = BiggestColliderRadius + ShapeTracer.CollisionShape.Extent.Size() + 1.f;
		FVector MaxPushedToLocation = PushStartLocation + CurrentPushDirection * HowFarToTraceFrom;

		FMovementQueryParams PushLocationParams;
		PushLocationParams.From = PushStartLocation;
		PushLocationParams.To = MaxPushedToLocation;

		TArray<FHazeHitResult> LocationFindHits;
		FVector PushTraceVector = MaxPushedToLocation - PushStartLocation;
		ShapeTracer.OverlapSweep(PushLocationParams, LocationFindHits);

		FVector PushedToLocation = FVector::ZeroVector;
		UPrimitiveComponent PushingPrimitive = nullptr;

		// fo r (const FHazeHitResult& PushStartHit : LocationFindHits)
		{
			FMovementQueryParams BackTraceQuery;
			BackTraceQuery.From = MaxPushedToLocation;
			BackTraceQuery.To = PushStartLocation - CurrentPushDirection * 1.f; // Add a little extra distance to the backtrace to guarantee we hit the same actors.
			
			// Ugly solution for getting the correct trace back location on something with multiple points.
			if (LocationFindHits.Num() > 0 && LocationFindHits[0].Time > 0.f)
				BackTraceQuery.From = PushStartLocation + PushTraceVector * LocationFindHits[0].Time;
			else if (LocationFindHits.Num() > 1)
				BackTraceQuery.From = PushStartLocation + PushTraceVector * LocationFindHits[1].Time;

			FVector TraceDelta = BackTraceQuery.To - BackTraceQuery.From;

			TArray<FHazeHitResult> BackTraceHits;
			// This is very broken if we don't find any of the primitives pushing us.
			if (!ensure(ShapeTracer.OverlapSweep(BackTraceQuery, BackTraceHits)))
				return PushStartLocation;

			for (FHazeHitResult& Hit : BackTraceHits)
			{
				if (ValidPushingPrimitives.Contains(Hit.Component))
				{
					// Pullback a little from the hit to avoid staying as touching.
					PushedToLocation = BackTraceQuery.From + (TraceDelta * Hit.Time);
					PushingPrimitive = Hit.Component;
					break;
				}
			}

		}

		// This is very broken if we don't find any of the primitives pushing us.
		if (!ensure(PushingPrimitive != nullptr))			
			return PushStartLocation;

		FVector OutputLocation = FVector::ZeroVector;
		{
			// Calculate the goal push location
			FMovementQueryParams PushQuery;
			PushQuery.From = PushStartLocation;
			PushQuery.To = PushedToLocation;
			
			ShapeTracer.IgnorePrimitives(ValidPushingPrimitives);
			if (ActorState.CurrentFloor != nullptr)
			{
				if (ActorState.CurrentFloor.Owner != nullptr)
				{
					ShapeTracer.StopIgnoringActor(ActorState.CurrentFloor.Owner);
				}
				else
				{
					ShapeTracer.StopIgnoringPrimitive(ActorState.CurrentFloor);
				}
			}
			
			OutputLocation = PushedToLocation;

			// Trace if the actors get squished on the way there.
			FHazeHitResult PushHit;
			if (ShapeTracer.CollisionSweep(PushQuery, PushHit))
			{
				// The Normal depentration should have resolved this.
				if (!ensure(!PushHit.bStartPenetrating))
					return PushStartLocation;

				FVector TraceDirection = PushedToLocation - PushStartLocation;
				FVector TracedDelta = TraceDirection * PushHit.Time;
				OutputLocation = PushStartLocation + TracedDelta;
				
				//Find the vector that goes along the wall
				FVector PushDirection = (PushQuery.To - PushQuery.From).GetSafeNormal();
				float PushDistance = (PushQuery.To - PushQuery.From).Size();
				FVector ReflectedDirection = Math::GetReflectionVector(PushDirection, PushHit.Normal);
				ReflectedDirection.Normalize();
				FVector RedirectVector = Math::ConstrainVectorToPlane(ReflectedDirection, PushHit.Normal).GetSafeNormal();

				//Find the corresponding length that makes use move the same amount in the original direction.
				float RedirectAngle = FMath::Acos(RedirectVector.DotProduct(PushDirection));
				float Length = PushDistance / FMath::Cos(RedirectAngle);
				float RedirectAngleDegress = FMath::RadiansToDegrees(RedirectAngle);

				const float UpScaledDeltaLength = PushDistance * 3.f;
				if (RedirectAngleDegress > 80.f || Length > UpScaledDeltaLength)
				{
					bOutIsSquished = true;
				}
				else
				{
					FVector RedirectedDelta = RedirectVector * Length;

					FMovementQueryParams RedirectQuery;
					RedirectQuery.From = OutputLocation;
					RedirectQuery.To = RedirectQuery.From + RedirectedDelta;

					FHazeHitResult RedirectHit;
					if (ShapeTracer.CollisionSweep(RedirectQuery, RedirectHit))
					{
						// We do assumption that if we hit something again that we are squished, we might have to change this to be a more advanced check.
						bOutIsSquished = true;
					}
				}
			}
		}

		OutPushData.SetPushData(PushingPrimitive, OutputLocation - PushStartLocation);
		return OutputLocation;
	}
};
