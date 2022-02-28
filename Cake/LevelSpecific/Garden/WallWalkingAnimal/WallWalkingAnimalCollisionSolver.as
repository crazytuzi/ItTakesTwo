import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;

void AddWallWalkingAnimalToSolver(AWallWalkingAnimal Animal, UHazeCollisionSolver Solver)
{
	auto AnimalSolver = Cast<UWallWalkingAnimalCollisionSolver>(Solver);
	if(AnimalSolver != nullptr)
	{
		AnimalSolver.Animal = Animal;
		AnimalSolver.AnimalMovementComponent = Animal.MoveComp;
	}
}

/* 
 * SOLVER
*/
class UWallWalkingAnimalCollisionSolver : UDefaultCharacterCollisionSolver
{	
	const int MaxIterations = 6;
	AWallWalkingAnimal Animal;
	UWallWalkingAnimalMovementComponent AnimalMovementComponent;

	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
#if EDITOR
		DebugComp.FrameReset(ActorState, MoveQuery, ShapeTracer.ColliderOffset, this);
		DebugComp.LogStartState(ActorState, MoveQuery);
#endif

		FCollisionSolverOutput Output;
		FVector OriginalWorldUp = ActorState.WorldUp;

		// Create and setup delta tracker
		FCollisionSolverState SolverState;
		SolverState.StartLocation = MoveQuery.Location;
		SolverState.CurrentLocation = MoveQuery.Location;
		SolverState.RemainingDelta = MoveQuery.Delta;
		SolverState.RemainingTime = FMath::Min(MoveQuery.DeltaTime, 1.f / 25.f); // we allow a frame to be a little bit lower than 30.
		SolverState.bLeavingGround = Animal.IsTransitioning();
		if(Animal.bHasBeenResetted || SolverState.bLeavingGround)
		{
			SolverState.CurrentVelocity = FVector::ZeroVector;
		}
		else
		{
			SolverState.CurrentVelocity = MoveQuery.Velocity;

			// We start the physics state with the old state
			SolverState.PhysicsState = ActorState.PhysicsState;
			SolverState.PreviousPhysicsState = ActorState.PhysicsState;	
		}

		const FCollisionSolverState OriginalSolverState = SolverState;

		if(PrepareFirstFrame(SolverState))
		{
			int Iterations = 0;		
			do
			{
	#if TEST
				FScopeCycleCounter Counter(GetIterationID(Iterations));
	#endif

	#if EDITOR
				DebugComp.LogIterationBegin(Iterations);
	#endif

				float IterationTime = CalculateIterationTime(SolverState);

				PrepareIterationStep(SolverState, IterationTime);
				PerformIterationStep(SolverState, IterationTime, Iterations == 0);

				if (SolverState.PhysicsState.bIsSquished)
					break;

			} while(++Iterations < 10 && !SolverState.IsDone());
					
		#if EDITOR
			DebugComp.LogEndState(SolverState, Output, Iterations);
		#endif
	
		}

		if(FinalStepdownHitGround(SolverState, OriginalWorldUp))
		{
			Output.PhysicalMove.MovedDelta = SolverState.MovedDelta;
			Output.PhysicalMove.RequestedVelocity = SolverState.CurrentVelocity;
			Output.PhysicsState = SolverState.PhysicsState;
			Output.PhysicsState.PushData = SolverState.PushData;
		}
		else
		{
			// We could not do anything so we just stay where we are
			Output.PhysicsState = OriginalSolverState.PhysicsState;
			Output.PhysicsState.PushData = SolverState.PushData;
		}

		OverrideActorStateWorldUp(OriginalWorldUp);

		return Output;
	}

	bool PrepareFirstFrame(FCollisionSolverState& SolverState) const
	{
		if(SolverState.bLeavingGround)
			return true;

		// We always prepare the frame by putting the spider on the ground
		// and updating its world up to align with the ground
		const FHitResult& CurrentGround = SolverState.PhysicsState.Impacts.DownImpact;
		if(!SolverState.IsGrounded() || !Animal.IsAnimalHitSurfaceStandable(CurrentGround))
		{
			const float CapsuleHalfHeight = ShapeTracer.GetCollisionShape().GetCapsuleHalfHeight() - 1;
			SolverState.CurrentLocation += ActorState.WorldUp * CapsuleHalfHeight;
			UpdateGroundedState(SolverState);
			SolverState.PreviousPhysicsState = ActorState.PhysicsState;
		}
		
		if(!SolverState.IsGrounded())
		{
			ensure(false, "Could not find a valid ground");
			SolverState.MarkIterationAsIncomplete();
			return false;
		}

		OverrideActorStateWorldUp(CurrentGround.Normal);

		const float DeltaSize = SolverState.RemainingDelta.Size();
		SolverState.RemainingDelta = Math::ConstrainVectorToPlane(
			SolverState.RemainingDelta,
			ActorState.WorldUp).GetSafeNormal();
		SolverState.RemainingDelta *= DeltaSize;

		return true;
	}

	void HandleSweepWasStartPenetrating(FCollisionSolverState& SolverState, bool bFirstIteration, FHazeHitResult Hit) const
	{
		const FHitResult CurrentGround = SolverState.PhysicsState.Impacts.DownImpact;
		if(!GIsTagedWithGravBootsWalkable(CurrentGround))
		{
			OverrideActorStateWorldUp(FVector::UpVector);
		}

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
		Super::HandleSweepWasStartPenetrating(SolverState, bFirstIteration, Hit);
	}

	void PrepareIterationStep(FCollisionSolverState& SolverState, float IterationTime) const override
	{
		Super::PrepareIterationStep(SolverState, IterationTime);
		SolverState.PhysicsState.GroundedState = SolverState.PreviousPhysicsState.GroundedState;
	}

	void PostSweep(FCollisionSolverState& SolverState) const override
	{
		const FHitResult CurrentGround = SolverState.PhysicsState.Impacts.DownImpact;
		if(Animal.IsAnimalHitSurfaceStandable(CurrentGround))
		{
			OverrideActorStateWorldUp(CurrentGround.Normal);
		}

		// Don't call super, we finish at the end
		//Super::PostSweep(SolverState);
	}

	void ProcessImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FHazeHitResult Impact) const
	{
		if (ImpactType == EImpactSurfaceType::Wall)
		{
			// We dont redirection multiple walls
			if(SolverState.LastImpactType == EImpactSurfaceType::Wall)
			{
				return;
			}

			if(PerformStepUp(SolverState, Impact))
			{
				return;
			}
		}

		SolverState.SetHit(ImpactType, Impact);

		FCollisionRedirectInput Redirect;
		Redirect.Impact = Impact;
		InitializeCharacterRedirect(SolverState, Redirect, ImpactType);

		RedirectImpact(SolverState, ImpactType, Redirect);
	}

	void InitializeCharacterRedirect(FCollisionSolverState& SolverState, FCollisionRedirectInput& Redirect, EImpactSurfaceType ImpactType) const override
	{
		const FHazeHitResult& Impact = Redirect.Impact;

		if (ImpactType == EImpactSurfaceType::Wall)
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
		else if (ImpactType == EImpactSurfaceType::Ground)
		{
			// If we where on the gravboots wall, but now we are not, we want to keep 
			if(!GIsTagedWithGravBootsWalkable(Impact.FHitResult) 
				&& GIsTagedWithGravBootsWalkable(SolverState.PhysicsState.Impacts.DownImpact))
			{
				Redirect.Method = EDeltaRedirectMethod::PlaneProject_PreserveLength;
				Redirect.RedirectNormal = Impact.Normal;
				SolverState.bVelocityIsDirty = true;
			}
			else
			{
				Redirect.Method = EDeltaRedirectMethod::PlaneProject_PreserveLength;
				Redirect.RedirectNormal = Impact.Normal;
				SolverState.bVelocityIsDirty = true;
			}
		}
		else
		{
			Super::InitializeCharacterRedirect(SolverState, Redirect, ImpactType);
		}
	}

	void UpdateGroundedState(FCollisionSolverState& SolverState) const override
	{
		if(SolverState.bLeavingGround)
			return;

		float BonusDistance = 0;
		if(!SolverState.IsGrounded())
		{
			const float CapsuleHalfHeight = ShapeTracer.GetCollisionShape().GetCapsuleHalfHeight() - 1;
			BonusDistance = CapsuleHalfHeight * 2;
		}
		else
		{	
			// If we are standing on regular ground, we just stepdown where we are
			const FHitResult OrginalGround = SolverState.PhysicsState.Impacts.DownImpact;
			if(!GIsTagedWithGravBootsWalkable(OrginalGround))
				OverrideActorStateWorldUp(FVector::UpVector);
		}

		const FHitResult& PossibleGround = SolverState.PhysicsState.Impacts.DownImpact;
		if(Animal.IsAnimalHitSurfaceStandable(PossibleGround))
		{
			// We need to start just a little bit out of the ground
			SolverState.CurrentLocation += ActorState.WorldUp * 2;
			BonusDistance += 2.f;	
		}
		
		PerformStepDown(SolverState, ActorState.StepDownAmount + BonusDistance);
		if(SolverState.IsGrounded() && Animal.IsAnimalHitSurfaceStandable(PossibleGround))
		{
			// We could slide a little bit on grounds so we lerp out here
			SolverState.CurrentLocation += ActorState.WorldUp;
			OverrideActorStateWorldUp(PossibleGround.Normal);
			return;
		}

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;

		// We have hit the wall with the stepdown, we now try to align with the walls normal instead
		// Making us step down in front of the wall
		FVector NewTraceDir = ActorState.WorldUp.ConstrainToPlane(PossibleGround.ImpactNormal);
		OverrideActorStateWorldUp(NewTraceDir);

		PerformStepDown(SolverState, ActorState.StepDownAmount + BonusDistance);
		if(SolverState.IsGrounded() && Animal.IsAnimalHitSurfaceStandable(PossibleGround))
		{
			// We could slide a little bit on grounds so we lerp out here
			SolverState.CurrentLocation += ActorState.WorldUp;
			OverrideActorStateWorldUp(PossibleGround.Normal);
			return;
		}

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;

		// We still could not find the ground, this is bad but we have to try one last time to just step down
		// using normal world up
		OverrideActorStateWorldUp(FVector::UpVector);
		PerformStepDown(SolverState, ActorState.StepDownAmount + BonusDistance);
		
		if(SolverState.IsGrounded() && Animal.IsAnimalHitSurfaceStandable(PossibleGround))
		{
			// We could slide a little bit on grounds so we lerp out here
			SolverState.CurrentLocation += ActorState.WorldUp;
			OverrideActorStateWorldUp(PossibleGround.Normal);
		}
	}

	bool FinalStepdownHitGround(FCollisionSolverState& SolverState, FVector OriginalWorldUp) const
	{
		if(SolverState.bLeavingGround)
			return true;

		// if(SolverState.IsGrounded())
		// 	return true;

		//OverrideActorStateWorldUp(OriginalWorldUp);
		UpdateGroundedState(SolverState);


		if(!SolverState.IsGrounded())
			return false;

		return true;
	}

	bool PerformStepUp(FCollisionSolverState& SolverState, FHazeHitResult WallImpact) const override
	{
		const FCollisionSolverState OldSolverState = SolverState;

		if(!Super::PerformStepUp(SolverState, WallImpact))
			return false;
		
		if(!SolverState.IsGrounded())
		{
			SolverState = OldSolverState;
			return false;
		}

		const FHitResult NewGround = SolverState.PhysicsState.Impacts.DownImpact;
		if(!Animal.IsAnimalHitSurfaceStandable(NewGround))
		{
			SolverState = OldSolverState;
			return false;
		}

		return true;
	}
	
	bool IsHitSurfaceWalkable(FCollisionSolverState SolverState, FHazeHitResult Hit) const override
	{
		return Animal.IsAnimalHitSurfaceWalkable(Hit.FHitResult);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetCustomVector() const
	{
		return Animal.SpiderWantedMovementDirection;
	}
};