
import Peanuts.Spline.SplineComponent;

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class USwarmMovementComponent : UActorComponent
{
	/* We'll assume that the actor has a Spline Component on it. */
	UPROPERTY(Category = "Movement")
	AActor FollowSplineActor = nullptr;

	/* Rubberbands will use this spline if set.
	 Otherwise fallback to using the FollowSplineActorSpline instead */
	UPROPERTY(Category = "Movement")
	AActor RubberbandSplineActor = nullptr;

	UPROPERTY(Category = "Movement", NotEditable)
	UHazeSplineComponent FollowSplineComp = nullptr;

	/* Used by Swarm AI to figure the middle location and size of the playground */
	UPROPERTY(Category = "Movement")
	AActor ArenaMiddleActor = nullptr;

	// delta moves in the world
	FVector TranslationVelocity = FVector::ZeroVector;

	// impulses/forces to the swarm root
	FVector PhysicsVelocity = FVector::ZeroVector;

	bool bReachedEndOfSpline = false;

	FVector SwarmAcceleration = FVector::ZeroVector;

	FTransform DesiredSwarmActorTransform = FTransform::Identity;
	FHazeSplineSystemPosition SplineSystemPos;
	float DistAlongSplineToUpdate = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DesiredSwarmActorTransform = GetOwner().GetActorTransform();

		if (FollowSplineActor != nullptr)
			FollowSplineComp = UHazeSplineComponent::Get(FollowSplineActor);
	}

	int GetSwarmMovingDirection(const float AccVelRatioThreshold = 2.f)
	{
		const float AccMag = SwarmAcceleration.Size();
		const float VelMag = PhysicsVelocity.Size();

		if(VelMag <= 0.f)
			return 0;

		const float Ratio =  AccMag / VelMag;
		if(Ratio < AccVelRatioThreshold)
			return 0;

		return FMath::Sign(SwarmAcceleration.DotProduct(PhysicsVelocity));
	}

	bool RayTraceMulti(
		const FVector& Start,
		const FVector& End, 
		TArray<FHitResult>& Hits,
		ETraceTypeQuery TraceType = ETraceTypeQuery::Visibility
	) const
	{
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Game::GetMay());
		IgnoreActors.Add(Game::GetCody());
		bool bHit = System::LineTraceMulti(
			Start,
			End,
			TraceType,
			true,		// Complex landscape trace needed for water 
			IgnoreActors,
			EDrawDebugTrace::None,
			Hits,
			bIgnoreSelf = true
		);
		return bHit;
	}

	FVector GetArenaMiddleCOM() const 
	{
		if(ArenaMiddleActor == nullptr)
			return FVector::ZeroVector;

		const UPrimitiveComponent ArenaRoot = Cast<UPrimitiveComponent>(ArenaMiddleActor.GetRootComponent());
		if (ArenaRoot != nullptr)
		{
			const FVector ArenaCOM = ArenaRoot.GetCenterOfMass();

			// this will happen when it isn't simulating? 
			// when collision is disabled?
			// when it is hidden!?
			if(ArenaCOM != FVector::ZeroVector)
			{
				// System::DrawDebugSphere( MiddleCOM, 1000.f, 32.f, FLinearColor::Red , 0.f);
				return ArenaCOM;
			}
		}

		return ArenaMiddleActor.GetActorLocation();
	}

	// Swarm root bone location
	float GetFractionOnSplineForSwarmLocation() const 
	{
		if(GetSplineToFollow() != nullptr)
			return GetSplineToFollow().FindFractionClosestToWorldLocation(DesiredSwarmActorTransform.GetLocation());
		return 0.f;
	}

	float GetFractionOnSplineForCustomLocation(const FVector& InWorldLocation) const
	{
		if(GetSplineToFollow() != nullptr)
			return GetSplineToFollow().FindFractionClosestToWorldLocation(InWorldLocation);
		return 0.f;
	}

	FVector GetSplineToFollowLocation() const
	{
		return GetSplineToFollowTransform().GetLocation();
	}

	FTransform GetSplineToFollowTransform() const
	{
		const UHazeSplineComponent Spline = GetSplineToFollow();
		if (Spline != nullptr)
			return Spline.GetWorldTransform();
		return FTransform::Identity;
	}
	
	UHazeSplineComponent GetSplineToFollow() const
	{
		return FollowSplineComp;
// 		if (FollowSplineActor == nullptr)
// 			return nullptr;
// 		return UHazeSplineComponent::Get(FollowSplineActor);
	}

	UFUNCTION(BlueprintPure, Category = "Swarm|Movement")
	bool HasSplineToFollow() const
	{
		return GetSplineToFollow() != nullptr;
	}

	void InitMoveAlongSpline()
	{
//		FVector ClosestWorldPos = FVector::ZeroVector;
//		GetSplineToFollow().FindDistanceAlongSplineAtWorldLocation(
//			DesiredSwarmActorTransform.GetLocation(),
//			ClosestWorldPos,
//			DistAlongSplineToUpdate
//		);

		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);

		SplineSystemPos = GetSplineToFollow().GetPositionClosestToWorldLocation(
			DesiredSwarmActorTransform.GetLocation(),
			true
		);

//		DesiredSwarmActorTransform.SetLocation(ClosestWorldPos);
	}

	bool MoveAlongSpline(float LerpStepSize, float Dt)
	{
		float LerpSpeed = LerpStepSize * Dt;
		ensure(LerpSpeed !=  0.f);
		UpdateMoveAlongSplineParams(LerpStepSize, LerpSpeed, Dt);
		return bReachedEndOfSpline;
	}

	
	bool MoveAlongSplineScaled(const float LerpStepSize, const float Dt)
	{
		// Lerp along the spline with a fixed speed 
		float LerpSpeed = LerpStepSize * Dt;

		// but also account for speed boost/slowdowns as defined by the splines Y-scale.
		// We clamp down because the scaling might dwarf nearby points to a very 
		// low number, making the swarm stop. 
		float SplineSpeedScaleMultiplier = SplineSystemPos.GetScale().Y;
		SplineSpeedScaleMultiplier = FMath::Max(0.2f, SplineSpeedScaleMultiplier);
		LerpSpeed *= SplineSpeedScaleMultiplier;

		UpdateMoveAlongSplineParams(LerpStepSize, LerpSpeed, Dt);

		return bReachedEndOfSpline;
	}

	void UpdateMoveAlongSplineParams(const float LerpStepSize, const float LerpSpeed, const float Dt)
	{
		ensure(LerpSpeed !=  0.f);
		ensure(LerpStepSize !=  0.f);

		FTransform TargetTransform = FTransform::Identity;

		const FTransform OwnerTransform = Owner.GetActorTransform();

		// Get us to the spline before we actually start following the spline. 
		FVector PointOnSpline = SplineSystemPos.GetWorldLocation();
		FVector TowardSplinePoint = PointOnSpline - OwnerTransform.GetLocation();
		float DistToSplinePoint_SQ = TowardSplinePoint.SizeSquared();

		if (DistToSplinePoint_SQ < FMath::Square(LerpStepSize))
		{
			bool bReachedEnd = !SplineSystemPos.Move(LerpSpeed);

			// Handle closed Loops @TODO proper fix is to account
			// for closed loops on begin play on the haze spline component
			if(bReachedEnd)
			{	
				if(SplineSystemPos.Spline.IsClosedLoop())
				{
					SplineSystemPos.Move(-SplineSystemPos.Spline.GetSplineLength());
					bReachedEnd = !SplineSystemPos.Move(LerpSpeed);
				}
				else
				{
					bReachedEndOfSpline = true;
					// OnReachedEndOfSpline.Broadcast();
				}
			}

			ensure(SplineSystemPos.GetWorldLocation() != FVector::ZeroVector);

			TargetTransform.SetLocation(SplineSystemPos.GetWorldLocation());
			TargetTransform.SetRotation(SplineSystemPos.GetWorldOrientation());
		}

		// reach the spline before we start following it
		if (DistToSplinePoint_SQ > SMALL_NUMBER)
		{
			// Updating these values will make it less likely that we'll catch up...
			// but it will prevent an eventual pop once we reach the target..
			PointOnSpline = SplineSystemPos.GetWorldLocation();
			TowardSplinePoint = PointOnSpline - OwnerTransform.GetLocation();
			DistToSplinePoint_SQ = TowardSplinePoint.SizeSquared();

			const float ReachSplineLerpSpeed = LerpSpeed * 1.0f;

			const float DistToSplinePoint = FMath::Sqrt(DistToSplinePoint_SQ);

//			PrintToScreen("DistToSplinePoint: " + DistToSplinePoint);

			if (DistToSplinePoint > ReachSplineLerpSpeed)
			{
				// Translation
				const FVector TowardsSplinePointNormalized = TowardSplinePoint / DistToSplinePoint;
				const FVector DeltaMove = TowardsSplinePointNormalized * ReachSplineLerpSpeed;
				TargetTransform.SetLocation(OwnerTransform.GetLocation() + DeltaMove);

				// Rotation
				const FQuat NewQuat = Math::MakeQuatFromX(TowardSplinePoint);
				TargetTransform.SetRotation(NewQuat);

//				System::DrawDebugPoint(
//					DesiredSwarmActorTransform.GetLocation(),
//					20.f,
//					FLinearColor::Red,
//					0.f
//				);

			}
		}

		DesiredSwarmActorTransform.SetLocation(TargetTransform.GetLocation());
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);

		// Make the interp smoother when not using procedural animations
		InterpolateToTargetRotation(TargetTransform.GetRotation(), 3.f, false, Dt);

//		System::DrawDebugPoint(
//			SplineSystemPos.GetWorldLocation(),
//			15.f,
//			FLinearColor::Blue,
//			0.f
//		);

	}

	FTransform GetSwarmTransformSteppedAlongSpline(const float StepSize) const
	{
		return GetSplineToFollow().StepTransformAlongSpline(Owner.GetActorTransform(), StepSize);
	}

	// Interpolates the owners transform to this transforms. Ignores scaling. 
	void LerpToTargetLocation(
		const FVector& TargetLocation,
		const float Alpha
	)
	{
		DesiredSwarmActorTransform.SetLocation(FMath::Lerp(DesiredSwarmActorTransform.GetLocation(), TargetLocation, Alpha));
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	void InterpolateToRotationOverTime(
		const FQuat& Start,
		const FQuat& Target,
		const float ElapsedTime,
		const float InDuration
	)
	{
		ensure(ElapsedTime >= 0.f);

		float Alpha = 1.f;
		if(InDuration > 0.f)
			Alpha = FMath::Clamp(ElapsedTime / InDuration, 0.f, 1.f);

		const FQuat LerpedQuat = FQuat::Slerp(Start, Target, Alpha);
		DesiredSwarmActorTransform.SetRotation(LerpedQuat);
	}

	// Interpolates the owners transform to this transforms. Ignores scaling. 
	void InterpolateToTargetOverTime(
		const FTransform& Start,
		const FTransform& Target,
		const float ElapsedTime,
		const float InDuration
	)
	{
		ensure(ElapsedTime >= 0.f);

		float Alpha = 1.f;
		if(InDuration > 0.f)
			Alpha = FMath::Clamp(ElapsedTime / InDuration, 0.f, 1.f);
		
	 	// Print("Alpha: " + Alpha);

		const FVector LerpedLocation = FMath::Lerp(
			Start.GetLocation(),
			Target.GetLocation(),
			Alpha
		);

		const FQuat LerpedQuat = FQuat::Slerp(
			Start.GetRotation(),
			Target.GetRotation(),
			Alpha
		);

		DesiredSwarmActorTransform.SetRotation(LerpedQuat);
		DesiredSwarmActorTransform.SetLocation(LerpedLocation);
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	// Interpolates the owners transform to this transforms. Ignores scaling. 
	void InterpolateToTarget(
		const FTransform& TargetTransform,
		float LerpSpeed,
		bool bConstantLerp,
		float Dt
	)
	{
		DesiredSwarmActorTransform = Math::InterpolateLocationAndRotationTo(
			DesiredSwarmActorTransform,
			TargetTransform,
			Dt,
			LerpSpeed,
			bConstantSpeed = bConstantLerp 
		);
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	void InterpolateToTargetLocation(
		const FVector& TargetLocation,
		float LerpSpeed,
		bool bConstantLerp,
		float Dt
	)
	{
		if (bConstantLerp)
		{
			DesiredSwarmActorTransform.SetLocation(FMath::VInterpConstantTo(
				DesiredSwarmActorTransform.GetLocation(),
				TargetLocation,
				Dt,
				LerpSpeed	
			));
		}
		else 
		{
			DesiredSwarmActorTransform.SetLocation(FMath::VInterpTo(
				DesiredSwarmActorTransform.GetLocation(),
				TargetLocation,
				Dt,
				LerpSpeed	
			));
		}
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	void InterpolateToTargetRotation(
		const FQuat& TargetQuat,
		float LerpSpeed,
		bool bConstantLerp,
		float Dt
	)
	{
		if (bConstantLerp) 
		{
			DesiredSwarmActorTransform.SetRotation(FMath::QInterpConstantTo(
				DesiredSwarmActorTransform.GetRotation(),
				TargetQuat,
				Dt,
				LerpSpeed	
			));
		}
		else 
		{
			DesiredSwarmActorTransform.SetRotation(FMath::QInterpTo(
				DesiredSwarmActorTransform.GetRotation(),
				TargetQuat,
				Dt,
				LerpSpeed	
			));
		}
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	void SlerpToTargetRotation(
		const FQuat& StartQuat,
		const FQuat& TargetQuat,
		const float Alpha 
	)
	{
		DesiredSwarmActorTransform.SetRotation(FQuat::Slerp(StartQuat, TargetQuat, Alpha));
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	FVector CalculateAirDrag(const float Coeff, const float Dt) const
	{
		// Calculate drag
		const float VelocitySQ = PhysicsVelocity.SizeSquared();
		const float DragForceMagnitude = -1.f * Coeff * VelocitySQ;
		float DragImpulseMagnitude = DragForceMagnitude * Dt;

		// Clamp drag
		const float DragImpulseMagnitudeSQ = DragImpulseMagnitude * DragImpulseMagnitude;
		if (DragImpulseMagnitudeSQ > VelocitySQ)
		{
			const float DownScale = FMath::Sqrt(VelocitySQ) * FMath::InvSqrt(DragImpulseMagnitudeSQ);
			DragImpulseMagnitude *= DownScale;
		}

		return TranslationVelocity.GetSafeNormal() * DragImpulseMagnitude;
	}

	void SteerToTarget(
		const FVector& TargetLocation,
		const float Dt,
		const float MaxSpeed = 5000.f,
		const float MaxForce = 2500.f 
	)
	{
		const FVector CurrentLocation = DesiredSwarmActorTransform.GetLocation();
		const FVector ToDesired = TargetLocation - CurrentLocation;
		const float ToDesiredMag_SQ = ToDesired.SizeSquared();

		// if (ToDesiredMag_SQ < THRESH_VECTOR_NORMALIZED)
		if (ToDesiredMag_SQ < 1.f)
			return;

		// steering acceleration
		const FVector ToDesiredNormalized = ToDesired * FMath::InvSqrt(ToDesiredMag_SQ);
		FVector Acceleration = (ToDesiredNormalized * MaxSpeed) - PhysicsVelocity;

		// Drag acceleration
		const FVector DragAcc = CalculateAirDrag(0.003f, Dt);
		Acceleration += DragAcc;

		Acceleration = Acceleration.GetClampedToMaxSize(MaxForce);

		PhysicsVelocity += Acceleration * Dt;
		const FVector DeltaMove = PhysicsVelocity * Dt;

		DesiredSwarmActorTransform.AddToTranslation(DeltaMove);
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	void SpringToTargetWithTime(const FVector& TargetLocation, const float Duration, const float Dt)
	{
		if (Duration == 0.f)
		{
			DesiredSwarmActorTransform.SetLocation(TargetLocation);
			ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
			return;
		}

		// const float LAMBERT_NOMINATOR = 9.23341f; // Within 0.1%; 1% is 6.63835
		const float LAMBERT_NOMINATOR = 6.638f; // Within 0.1%; 1% is 6.63835
		// const float LAMBERT_NOMINATOR = 5.f; 

		const float Acceleration = LAMBERT_NOMINATOR / Duration;
		const FVector ToTarget = TargetLocation - DesiredSwarmActorTransform.GetLocation();

		PhysicsVelocity += ToTarget * FMath::Square(Acceleration) * Dt;
		PhysicsVelocity /= FMath::Square(1.f + Acceleration * Dt);

  		ensure(PhysicsVelocity.ContainsNaN() == false);

		DesiredSwarmActorTransform.AddToTranslation(PhysicsVelocity * Dt);
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	void SpringToTargetLocation(
		const FVector& TargetLocation,
		const float Stiffness,
		const float Damping,
		const float Dt
	)
	{
		const float IdealDampingValue = 2.f * FMath::Sqrt(Stiffness);
		const FVector ToSwarm = DesiredSwarmActorTransform.GetLocation() - TargetLocation;

		PhysicsVelocity -= (ToSwarm*Dt*Stiffness);
		PhysicsVelocity /= (1.f + (Dt*Dt*Stiffness) + (Damping*IdealDampingValue*Dt));

  		ensure(PhysicsVelocity.ContainsNaN() == false);

		DesiredSwarmActorTransform.AddToTranslation(PhysicsVelocity * Dt);
		ensure(DesiredSwarmActorTransform.GetLocation() != FVector::ZeroVector);
	}

	FQuat GetFacingRotationTowardsActor(const AHazeActor TargetActor) const
	{
		return GetFacingRotationTowardsLocation(TargetActor.GetActorLocation());
	}

	FQuat GetFacingRotationTowardsTransform(FTransform TargetTransform) const
	{
		return GetFacingRotationTowardsLocation(TargetTransform.GetLocation());
	}

	FQuat GetFacingRotationTowardsLocation(FVector TargetLocation) const
	{
		const FVector SwarmLocation = Owner.GetActorLocation();
		const FVector TowardsTarget = TargetLocation - SwarmLocation;
  		const FQuat NewQuat = TowardsTarget.ToOrientationQuat();
  		// const FQuat NewQuat = Math::MakeQuatFromX(TowardsTarget);
		return NewQuat;
	}

	FSwarmCRSplinePoint GetLocationOnCRSplineWithCustomSpeed(
		const FVector& StartHandle,
		const TArray<FSwarmCRSplinePoint>& InSplinePoints,
		const FVector& EndHandle,
		const float InAlpha,
		const float Damping = 0.5f
	)
	{
		// we need at least 2 points for this to work.
		if (InSplinePoints.Num() < 2)
			return FSwarmCRSplinePoint();

		TArray<FVector> Points;
		for (const FSwarmCRSplinePoint& CRSplinePoint : InSplinePoints)
			Points.Add(CRSplinePoint.Location);

//   		DebugSwarmCRSpline(StartHandle, Points, EndHandle, InAlpha);

		Points.Insert(StartHandle, 0);
		Points.Add(EndHandle);

		const float SplineAlpha = (InSplinePoints.Num() - 1) * InAlpha;
		const int32 SplineIndex = SplineAlpha;

		if (SplineIndex == (InSplinePoints.Num() - 1))
		{
			FSwarmCRSplinePoint CRSplinePoint;
			CRSplinePoint.Location = Math::GetLocationOnCRSegment(
				Points[Points.Num() - 4],
				Points[Points.Num() - 3],
				Points[Points.Num() - 2],
				Points[Points.Num() - 1],
				1.f,
				Damping
			);

			CRSplinePoint.Speed = InSplinePoints[SplineIndex].Speed;
			return CRSplinePoint;
		}
		else if (SplineIndex == 0)
		{
			FSwarmCRSplinePoint CRSplinePoint;
			CRSplinePoint.Location = Math::GetLocationOnCRSegment(
				Points[0],
				Points[1],
				Points[2],
				Points[3],
				SplineAlpha,
				Damping
			);

			CRSplinePoint.Speed = FMath::Lerp(
				InSplinePoints[SplineIndex].Speed,
				InSplinePoints[SplineIndex + 1].Speed,
				SplineAlpha
			);

			return CRSplinePoint;
		}
		else
		{
			const float SegmentAlpha = FMath::Fmod(SplineAlpha, SplineIndex);
			FSwarmCRSplinePoint CRSplinePoint;
			CRSplinePoint.Location = Math::GetLocationOnCRSegment(
				Points[SplineIndex],
				Points[SplineIndex + 1],
				Points[SplineIndex + 2],
				Points[SplineIndex + 3],
				SegmentAlpha,
				Damping
			);

			CRSplinePoint.Speed = FMath::Lerp(
				InSplinePoints[SplineIndex].Speed,
				InSplinePoints[SplineIndex + 1].Speed,
				SegmentAlpha
			);

			return CRSplinePoint;
		}
	}

	bool HasPassedCRSplinePoint(
		const FVector& SplinePointToCheck,
		const TArray<FVector>& SplinePoints,
		const float Alpha 
	) const
	{
		int32 IndexOfPointToCheck = SplinePoints.FindIndex(SplinePointToCheck);
		if (IndexOfPointToCheck == -1)
			return false;

		const int32 CurrentSplineIndex = (SplinePoints.Num() - 1) * Alpha;

		return IndexOfPointToCheck <= CurrentSplineIndex;
	}

	void DebugSwarmCRSpline(
		const FVector& StartHandle,
		const TArray<FVector>& InSplinePoints,
		const FVector& EndHandle,
		const float InAlpha
	)
	{
		System::DrawDebugPoint(
			StartHandle,
			10.f,
			FLinearColor::Blue,
			0.f
		);

		System::DrawDebugLine(
			StartHandle,
			InSplinePoints[0],
			FLinearColor::Blue,
			0.f,
			5.f
		);

		System::DrawDebugPoint(
			EndHandle,
			10.f,
			FLinearColor::Red,
			0.f
		);

		System::DrawDebugLine(
			EndHandle,
			InSplinePoints.Last(),
			FLinearColor::Red,
			0.f,
			5.f
		);

		for (int i = 0; i < InSplinePoints.Num(); ++i)
		{
			FLinearColor Farg = FLinearColor::Yellow;
			if (i == 0)
				Farg = FLinearColor::Blue;
			else if(i == InSplinePoints.Num() -1)
				Farg = FLinearColor::Red;

			System::DrawDebugPoint(
				InSplinePoints[i],
				10.f,
				Farg,
				0.f
			);
		}
	}
}

struct FSwarmCRSplinePoint
{
	FSwarmCRSplinePoint()
	{
		Location = FVector::ZeroVector;
		Speed = 0.f;
	}

	FSwarmCRSplinePoint(FVector InPoint, float InSpeed)
	{
		Location = InPoint;
		Speed = InSpeed;
	}

	FVector Location = FVector::ZeroVector;
	float Speed = 0.f;
};





















