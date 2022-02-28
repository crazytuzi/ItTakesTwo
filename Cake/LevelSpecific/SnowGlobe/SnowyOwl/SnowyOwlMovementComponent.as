import Vino.Movement.Swinging.SwingPointComponent;
import Peanuts.Spline.SplineComponent;

struct FSnowyOwlTransition
{
	FVector InitialLocation;
	UHazeSplineComponent From = nullptr;
	float ExitDistance;
	FVector ExitTangent;
	UHazeSplineComponent To = nullptr;
	float EntryDistance;
	FVector EntryTangent;
	float Length;

	FVector GetExitLocation()
	{
		if (From != nullptr)
			return From.GetLocationAtDistanceAlongSpline(ExitDistance, ESplineCoordinateSpace::World);

		return InitialLocation;
	}

	FVector GetEntryLocation()
	{
		return To.GetLocationAtDistanceAlongSpline(EntryDistance, ESplineCoordinateSpace::World);
	}

	FVector GetExitTangentLocation(float TangentDistance)
	{
		return GetExitLocation() + ExitTangent * TangentDistance;
	}

	FVector GetEntryTangentLocation(float TangentDistance)
	{
		return GetEntryLocation() + EntryTangent * TangentDistance;
	}

	FVector GetLocationAtDistance(float Distance, float TangentDistance)
	{
		if (Length == 0.f)
			return FVector::ZeroVector;

		float Alpha = FMath::Clamp(Distance / Length, 0.f, 1.f);
		FVector SampleLocation = Math::GetPointOnCubicBezierCurveConstantSpeed(GetExitLocation(),
			GetExitTangentLocation(TangentDistance),
			GetEntryTangentLocation(TangentDistance),
			GetEntryLocation(),
			Alpha);

		return SampleLocation;
	}

	bool IsValid()
	{
		return (To != nullptr);
	}
}

class USnowyOwlMovementComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(NotVisible)
	USwingPointComponent SwingPointComp;

	UPROPERTY(Category = "Movement")
	AActor EntrySplineActor;

	UPROPERTY(Category = "Movement")
	AActor LoopSplineActor;

	UPROPERTY(Category = "Movement")
	AActor TourSplineActor;

	// Base movement speed.
	UPROPERTY(Category = "Movement")
	float Speed = 1000.f;

	// Movement speed while "touring" the town.
	UPROPERTY(Category = "Movement")
	float TourSpeed = 2500.f;

	UPROPERTY(Category = "Movement")
	float SpeedInterpRate = 1.f;

	UPROPERTY(Category = "Movement")
	float RotationInterpRate = 10.f;
	
	/* Scales transition tangent distance, where one is equal to the length of the transition.
	   High value may increase error in speed but allows for smoother transitions. */
	UPROPERTY(Category = "Movement")
	float TangentDistanceScale = 0.25f;

	// Stores transitions generated in editor for runtime use.
	UPROPERTY(Category = "Movement")
	TArray<FSnowyOwlTransition> StoredTransitions;

	// Manually set the tour entry distance.
	UPROPERTY(Category = "Movement")
	float OverrideEntryDistance = -1.0f;

	// Manually set the tour exit distance.
	UPROPERTY(Category = "Movement")
	float OverrideExitDistance = -1.0f;

	float Distance;
	float CurrentSpeed;
	float AvoidanceModifier;
	UHazeSplineComponent CurrentSpline;
	
	FTransform Transform;
	float LastAppliedMove;

	bool bIsTransitioning;
	FSnowyOwlTransition Transition;

	UPROPERTY(NotVisible)
	UHazeSplineComponent EntrySpline;
	UPROPERTY(NotVisible)
	UHazeSplineComponent LoopSpline;
	UPROPERTY(NotVisible)
	UHazeSplineComponent TourSpline;

	UFUNCTION(CallInEditor, Category = "Movement")
	void RegenerateTransitions()
	{
		StoredTransitions.Empty();

		if (LoopSpline == nullptr)
			return;

		if (EntrySpline != nullptr)
		{
			FVector EntryEndLocation = EntrySpline.GetLocationAtTime(1.f, ESplineCoordinateSpace::World);
			FSnowyOwlTransition EntryToLoop = CreateTransition(EntrySpline, LoopSpline, EntryEndLocation);
			StoredTransitions.Add(EntryToLoop);
		}

		if (TourSpline != nullptr)
		{
			FVector TourEndLocation = TourSpline.GetLocationAtTime(1.f, ESplineCoordinateSpace::World);
			FSnowyOwlTransition TourToLoop = CreateTransition(TourSpline, LoopSpline, TourEndLocation);
			StoredTransitions.Add(TourToLoop);

			FVector TourEntryLocation = TourSpline.GetLocationAtTime(0.f, ESplineCoordinateSpace::World);
			FSnowyOwlTransition LoopToTour = CreateTransition(LoopSpline, TourSpline, TourEndLocation);
			StoredTransitions.Add(LoopToTour);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		EntrySpline = (EntrySplineActor != nullptr) ? UHazeSplineComponent::Get(EntrySplineActor) : nullptr;
		LoopSpline = (LoopSplineActor != nullptr) ? UHazeSplineComponent::Get(LoopSplineActor) : nullptr;
		TourSpline = (TourSplineActor != nullptr) ? UHazeSplineComponent::Get(TourSplineActor) : nullptr;

		RegenerateTransitions();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		SwingPointComp = USwingPointComponent::Get(Owner);

		SwingPointComp.OnSwingPointAttached.AddUFunction(this, n"HandlePlayerAttached");

		if (EntrySpline != nullptr)
		{
			Owner.ActorLocation = EntrySpline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);
			CurrentSpline = EntrySpline;
		}
		else if (LoopSpline != nullptr)
		{
			float ClosestDistance = LoopSpline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
			FVector ClosestLocation = LoopSpline.GetLocationAtDistanceAlongSpline(ClosestDistance, ESplineCoordinateSpace::World);
			Owner.ActorLocation = ClosestLocation;

			CurrentSpline = LoopSpline;
			Distance = ClosestDistance;
		}
	}

	// Only moves local transform forward; use ApplyMove() to move the actor to the new position.
	void Move(float DeltaTime)
	{
		if (HasControl())
		{
			CurrentSpeed = FMath::FInterpTo(CurrentSpeed, GetTargetSpeed(), DeltaTime, SpeedInterpRate);

			if (CurrentSpline != nullptr && !IsTransitioning())
			{
				const float PreviousDistance = Distance;
				const float SplineLength = GetExitDistance();
				const float DistanceRemaining = SplineLength - Distance;
				const float MovementStep = FMath::Min(CurrentSpeed * DeltaTime, DistanceRemaining);

				Distance = FMath::Clamp(Distance + MovementStep, 0.f, SplineLength);
				
				// Check if we're traversing an exit as defined by the transition
				if (Transition.IsValid() && FMath::IsWithinInclusive(Transition.ExitDistance, PreviousDistance, Distance))
				{
					BeginTransition(MovementStep - DistanceRemaining);
					return;
				}

				// Reaching end of spline, wrap looped splines
				// or return to loop if we're exiting a linear spline
				if (MovementStep >= DistanceRemaining)
				{
					if (CurrentSpline.IsClosedLoop())
					{
						Distance -= SplineLength;
					}
					else
					{
						PrepareTransition(LoopSpline);
						BeginTransition(0.f);
						return;
					}
				}

				const FTransform SplineTransform = CurrentSpline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
				Transform.Location = SplineTransform.Location;
				Transform.Rotation = SplineTransform.Rotation;
			}
			else if (Transition.IsValid())
			{
				const float PreviousDistance = Distance;
				const float DistanceRemaining = Transition.Length - Distance;
				const float MovementStep = FMath::Min(CurrentSpeed * DeltaTime, DistanceRemaining);

				Distance = FMath::Clamp(Distance + MovementStep, 0.f, Transition.Length);

				// Reaching end of transition
				if (MovementStep >= DistanceRemaining)
				{
					FinishTransition(MovementStep - DistanceRemaining);
					return;
				}

				const float TangentDistance = Transition.Length * TangentDistanceScale;
				const FVector PreviousLocation = Transform.Location; 
				Transform.Location = Transition.GetLocationAtDistance(Distance, TangentDistance);
				Transform.Rotation = (Transform.Location - PreviousLocation).GetSafeNormal().Rotation().Quaternion();
			}

			CrumbComp.SetCustomCrumbVector(Transform.Location);
			CrumbComp.SetCustomCrumbRotation(Transform.Rotator());
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized Params;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, Params);

			Transform.Location = Params.CustomCrumbVector;
			Transform.Rotation = Params.CustomCrumbRotator.Quaternion();
		}
	}

	// Moves the actor to the current transform.
	void ApplyMove(float DeltaTime)
	{
		LastAppliedMove = Time::GameTimeSeconds;
		
		FVector Location = Transform.Location;
		FQuat Rotation = Math::MakeQuatFromZX(FVector::UpVector, Transform.Rotation.ForwardVector);
		Rotation = FQuat::Slerp(Owner.ActorQuat, Rotation, DeltaTime * RotationInterpRate);

		Owner.SetActorLocationAndRotation(Location, Rotation.Rotator());
	}

	void PrepareTransition(UHazeSplineComponent Spline)
	{
		if (Spline == nullptr)
			return;

		// Look for a matching stored transition
		for (int i = 0; i < StoredTransitions.Num(); ++i)
		{
			if (CurrentSpline != nullptr && StoredTransitions[i].From == CurrentSpline && Spline == StoredTransitions[i].To)
			{
				Transition = StoredTransitions[i];
				return;
			}
		}

		// Haven't stored this transition, create a new one
		Transition = CreateTransition(CurrentSpline, Spline, Owner.ActorLocation);

		// Don't want to store location => spline transitions
		// since we'll most likely never transition from the same location again
		if (CurrentSpline != nullptr)
			StoredTransitions.Add(Transition);
	}

	void BeginTransition(float DistanceRemainder)
	{
		bIsTransitioning = true;
		Distance = DistanceRemainder;
	}

	void FinishTransition(float DistanceRemainder)
	{
		CurrentSpline = Transition.To;
		Distance = Transition.EntryDistance + DistanceRemainder;
		bIsTransitioning = false;
		Transition = FSnowyOwlTransition();
	}

	UFUNCTION(BlueprintPure)
	float GetTargetSpeed()
	{
		if (CurrentSpline == nullptr && !Transition.IsValid())
			return 0.f;

		return (IsTouring() ? TourSpeed : Speed) * (1.f + AvoidanceModifier);
	}

	// Gets the distace of exit for the current spline, accounts for manual overrides.
	UFUNCTION(BlueprintPure)
	float GetExitDistance()
	{
		if (CurrentSpline == nullptr)
			return 0.f;

		if (CurrentSpline == TourSpline && OverrideExitDistance > 0.f)
			return OverrideExitDistance;

		return CurrentSpline.SplineLength;
	}

	UFUNCTION(BlueprintPure)
	bool CanMove()
	{
		if (CurrentSpline == nullptr && !Transition.IsValid())
			return false;

		if (FMath::IsNearlyZero(GetTargetSpeed()) && FMath::IsNearlyZero(Speed))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool IsTouring()
	{
		return (CurrentSpline == TourSpline || (Transition.IsValid() && Transition.To == TourSpline));
	}

	UFUNCTION(BlueprintPure)
	bool IsTransitioning()
	{
		return (Transition.IsValid() && bIsTransitioning);
	}

	private FSnowyOwlTransition CreateTransition(UHazeSplineComponent From, UHazeSplineComponent To, const FVector& FromLocation)
	{
		FSnowyOwlTransition NewTransition;

		// We need to know where the owner is if there is no active spline
		NewTransition.InitialLocation = Owner.ActorLocation;

		if (To != nullptr)
		{
			NewTransition.To = To;
			NewTransition.EntryDistance = To.IsClosedLoop() ? 
				CalculateTransitionDistance(To, FromLocation, true) : 0.f;

			// Manually overrides entry distance to tour spline
			if (To == TourSpline && OverrideEntryDistance > 0.f)
				NewTransition.EntryDistance = OverrideEntryDistance;

			NewTransition.EntryTangent = -To.GetTransformAtDistanceAlongSpline(NewTransition.EntryDistance,
				ESplineCoordinateSpace::World).Rotation.ForwardVector;
		}

		if (From != nullptr)
		{
			NewTransition.From = From;
			NewTransition.ExitDistance = From.IsClosedLoop() ? 
				CalculateTransitionDistance(From, NewTransition.GetEntryLocation()) : From.SplineLength;

			// Manually overrides exit distance from tour spline
			if (From == TourSpline && OverrideExitDistance > 0.f)
				NewTransition.ExitDistance = OverrideExitDistance;

			NewTransition.ExitTangent = From.GetTransformAtDistanceAlongSpline(NewTransition.ExitDistance,
				ESplineCoordinateSpace::World).Rotation.ForwardVector;
		}

		NewTransition.Length = (NewTransition.GetExitLocation() - NewTransition.GetEntryLocation()).Size();

		return NewTransition;
	}

	private float CalculateTransitionDistance(UHazeSplineComponent TargetSpline, FVector FromLocation, bool bInvertTargetAngle = false, float StepSize = 64.f)
	{
		if (TargetSpline == nullptr)
			return 0.f;

		float MaxStepSize = FMath::Max(StepSize, 16.f);

		float BestAngle = MAX_flt;
		float BestDistance = 0.f;

		float CurrentDistance = 0.f;
		while (CurrentDistance < TargetSpline.SplineLength)
		{
			const FTransform SplineTransform = TargetSpline.GetTransformAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World);
			FVector ToTarget = (FromLocation - SplineTransform.Location).GetSafeNormal();

			if (bInvertTargetAngle)
				ToTarget *= -1.f;

			const float Angle = FMath::Acos(ToTarget.DotProduct(SplineTransform.Rotation.ForwardVector));
			if (Angle < BestAngle)
			{
				BestAngle = Angle;
				BestDistance = CurrentDistance;
			}

			CurrentDistance += MaxStepSize;
		}

		return BestDistance;
	}

	UFUNCTION()
	private void HandlePlayerAttached(AHazePlayerCharacter Player)
	{
		if (HasControl() && !IsTouring())
			PrepareTransition(TourSpline);
	}
}