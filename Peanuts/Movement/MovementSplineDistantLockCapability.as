import Peanuts.Movement.DeltaProcessor;
import Vino.Movement.SplineLock.ConstraintHandler;
import Vino.Movement.SplineLock.SplineLockComponent;


class ULockCharacterToSplineAndDistanceCapability : UHazeCapability
{
	USplineLockAndDistansLockProcessor SplineLockProcessor;

	USplineLockComponent SplineLockComp;
	UHazeBaseMovementComponent MoveComp;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);
		MoveComp = UHazeBaseMovementComponent::GetOrCreate(Owner);
		SplineLockProcessor = USplineLockAndDistansLockProcessor();
		SplineLockProcessor.SplineLockComp = SplineLockComp;

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SplineLockComp.IsActiveltyConstraining())
			return EHazeNetworkActivation::DontActivate;

		if (SplineLockComp.ActiveLockType != ESplineLockType::Distance)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SplineLockComp.IsActiveltyConstraining())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SplineLockComp.ActiveLockType != ESplineLockType::Distance)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SplineLockProcessor.OtherPlayer = PlayerOwner.OtherPlayer;
		MoveComp.UseDeltaProcessor(SplineLockProcessor, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.StopDeltaProcessor(this);
	}
}


class USplineLockAndDistansLockProcessor : UDeltaProcessor
{
	AHazePlayerCharacter OtherPlayer;
	USplineLockComponent SplineLockComp;

	FHazeHitResult LastHit;

	private FSplineConstraintHandler& GetConstrainer() property
	{
		return SplineLockComp.Constrainer;
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Constrainer.MarkAsDirty();
	}

	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTime) override
	{
		if (!ensure(Constrainer.IsConstrained()))
			return;

		UHazeSplineComponentBase DummySpline;
		float CurrentDistanceOnSpline = 0.f;
		bool bDummyForward;
		Constrainer.CurrentSplineLocation.BreakData(DummySpline, CurrentDistanceOnSpline, bDummyForward);

		float OtherPlayerDistance = Constrainer.SplineToLockMovementTo.GetDistanceAlongSplineAtWorldLocation(OtherPlayer.ActorLocation);
		float SplineDistanceDif = OtherPlayerDistance - CurrentDistanceOnSpline;

		float MoveDirection = FMath::Sign(SolverState.RemainingDelta.DotProduct(Constrainer.CurrentSplineLocation.WorldTangent));
		if (FMath::Sign(SplineDistanceDif) != MoveDirection)
		{
			if (FMath::Abs(SplineDistanceDif) > SplineLockComp.PlayerMaxSplineDistanceDif)
			{
				SolverState.RemainingDelta = SolverState.RemainingDelta.ConstrainToDirection(ActorState.WorldUp);
				return;
			}
		}

		Constrainer.CorrectDeltaToSpline(ActorState, SolverState, LastHit);
		Constrainer.UpdateExpectedData(SolverState, IterationTime);

		LastHit = FHazeHitResult();
	}

	void ImpactCorrection(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FHazeHitResult& Impact) override
	{
		if (!ensure(Constrainer.IsConstrained()))
			return;

		LastHit = Impact;

		// If we are constrained, we want to manipulate the normals of the hit so that we always get redirected _along_ the horizontal direction of the spline
		//	(or more accurately, the horizontal direction of our delta)
		// If we go purely on the spline-tangent, sometimes a little bit of horizontal delta will still be left after the redirect, and we get stuck against a wall
		FVector ConstrainForward = SolverState.RemainingDelta.ConstrainToPlane(ActorState.WorldUp);
		FVector ConstrainRight = ConstrainForward.CrossProduct(ActorState.WorldUp);
		ConstrainRight.Normalize();

		if (ConstrainRight.IsNearlyZero())
		{
			// If we dont have any horizontal delta though, constrain along the spline! It should be fine!
			ConstrainRight = Constrainer.GetCurrentRightVector();
		}

		FHitResult ModifiedResult = Impact.FHitResult;
		ModifiedResult.Normal = Impact.Normal.ConstrainToPlane(ConstrainRight).GetSafeNormal();
		ModifiedResult.ImpactNormal = Impact.ImpactNormal.ConstrainToPlane(ConstrainRight).GetSafeNormal();
		Impact.OverrideFHitResult(ModifiedResult);
	}

	void PostIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState) override
	{
		if (!ensure(Constrainer.IsConstrained()))
			return;

		Constrainer.UpdatePositionOnSpline(SolverState.LastMovedDelta, ActorState.WorldUp);
	}
}
