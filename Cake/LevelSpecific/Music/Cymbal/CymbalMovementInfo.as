
struct FCymbalMovementOutput
{
	AActor HitActor;	// If trace was performed
	FVector Location;	// new location in world space
	FVector MovementDelta;
	FVector LastLocation;
	FRotator Rotation;
	bool bHitSomething = false; // if the trace was a blocking hit
}

struct FCymbalMovement
{
	private FVector _TargetLocation;
	private FVector _StartLocation;
	private FVector _CurrentLocation;
	private FVector _LastLocation;
	private FVector _PreviousTargetLocation;

	private FVector _RandomDirection;

	private float _TargetTime = 0;

	private float _Elapsed = 0;

	private float AngleOffset = 0.0f;

	private bool bReturnToOwner = false;
	bool bSpring = false;

	void StartMovement(FVector StartLocation, FVector TargetLocation, float InAngle, float Speed, TArray<AActor> IgnoreActors, bool bInSpring, float PredictionLag)
	{
		bReturnToOwner = false;
		bSpring = bInSpring;
		_StartLocation = _CurrentLocation = _LastLocation = StartLocation;
		Internal_StartMovement(StartLocation, TargetLocation, InAngle, Speed, IgnoreActors, PredictionLag);
	}

	void ReturnToOwner(FVector StartLocation, FVector TargetLocation, float InAngle, float Speed, TArray<AActor> IgnoreActors, bool bInSpring, float PredictionLag)
	{
		bReturnToOwner = true;
		bSpring = bInSpring;
		_PreviousTargetLocation = _CurrentLocation;
		_StartLocation = _CurrentLocation = StartLocation;
		Internal_StartMovement(StartLocation, TargetLocation, InAngle, Speed, IgnoreActors, PredictionLag);
	}

	private void Internal_StartMovement(FVector StartLocation, FVector TargetLocation, float InAngle, float Speed, TArray<AActor> IgnoreActors, float PredictionLag)
	{
		_TargetLocation = TargetLocation;
		const float DistanceToTarget = FMath::Max(StartLocation.Distance(TargetLocation), 1.0f);
		const float DistanceHalf = DistanceToTarget * 0.5f;
		_TargetTime = FMath::Max(((DistanceToTarget / Speed) - PredictionLag), 0.1f);
		_Elapsed = 0;

		const FVector DirectionTo = (TargetLocation - StartLocation).GetSafeNormal();

		FVector OffsetVector = DirectionTo.RotateAngleAxis(InAngle, FVector::UpVector);
		//System::DrawDebugLine(_StartLocation, _StartLocation + OffsetVector * DistanceHalf, FLinearColor::Red, 5, 10);

		const FVector EndLoc = _StartLocation + OffsetVector * DistanceHalf;
		FHitResult Hit;
		
		System::LineTraceSingle(_StartLocation, EndLoc, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
		
		AngleOffset = InAngle;
		
		if(Hit.bBlockingHit)
		{
			FVector ClosestPoint = Math::ProjectPointOnInfiniteLine(_StartLocation, DirectionTo, Hit.ImpactPoint);
			const float DistanceToPoint = ClosestPoint.Distance(Hit.ImpactPoint);
			//System::DrawDebugPoint(ClosestPoint, 10, FLinearColor::Blue, 5);
			const float AngularOffsetFraction = InAngle * (Hit.Distance / DistanceHalf);
			//PrintToScreen("AngularOffsetFraction " + AngularOffsetFraction, 5);
			AngleOffset = DistanceToPoint;
		}
		else
		{
			const FVector ClosestPoint = Math::ProjectPointOnInfiniteLine(_StartLocation, DirectionTo, EndLoc);
			const float DistanceToPoint = ClosestPoint.Distance(EndLoc);
			AngleOffset = DistanceToPoint;
		}
	}

	private const float Exp = 9.8f;
	private const float A = 1.0f;
	private const float B = 0.3f;

	void MoveWithBezier(float DeltaTime, FVector TargetLocation, FCymbalMovementOutput& OutMovement, bool bDebugDraw = false)
	{
		const float Distance = (TargetLocation - _StartLocation).Size();
		float Mul = 1.0f;

		if(bSpring)
		{
			const float DistanceCurrentSq = _CurrentLocation.DistSquared(TargetLocation);
			const float Alpha = FMath::Clamp(DistanceCurrentSq / FMath::Max(FMath::Square(Distance), 1.0f), 0.0f, 1.0f);
			Mul = FMath::EaseOut(B, A,  Alpha, Exp);
		}

		//PrintToScreen("Mul: " + Mul);

		_Elapsed = FMath::Min(_Elapsed + (DeltaTime * Mul), _TargetTime);
		
		const float DistanceHalf = Distance * 0.5f;

		const FVector DistanceBetweenA = (TargetLocation - _StartLocation) * 0.10f;
		const FVector DistanceBetweenB = (TargetLocation - _StartLocation) * 0.55f;
		const FVector DirectionBetween = (TargetLocation - _StartLocation).GetSafeNormal();
		const FVector RotatedDirection = DirectionBetween.RotateAngleAxis(AngleOffset, FVector::UpVector);
		const FVector RotatedDirection2 = DirectionBetween.RotateAngleAxis(90.0f, FVector::UpVector);
		
		const FVector ControlPointA = (_StartLocation + (DirectionBetween * DistanceHalf)) + RotatedDirection2 * AngleOffset;
		const FVector ControlPointB = TargetLocation + RotatedDirection2 * AngleOffset;

		Internal_Move(_StartLocation, ControlPointA, ControlPointB, TargetLocation, OutMovement, bDebugDraw);
	}

	void ReturnWithBezier(float DeltaTime, FVector TargetLocation, FCymbalMovementOutput& OutMovement, bool bDebugDraw = false)
	{
		const float Distance = (TargetLocation - _StartLocation).Size();
		float Mul = 1.0f;

		if(bSpring)
		{
			const float DistanceCurrentSq = _CurrentLocation.DistSquared(_PreviousTargetLocation);
			const float DistancePrevTargetSq = TargetLocation.DistSquared(_PreviousTargetLocation);
			const float Alpha = FMath::Clamp(DistanceCurrentSq / FMath::Max(DistancePrevTargetSq, 1.0f), 0.0f, 1.0f);
			Mul = FMath::EaseOut(B, A, Alpha, Exp);
		}

		//PrintToScreen("Mul: " + Mul);

		_Elapsed = FMath::Min(_Elapsed + (DeltaTime * Mul), _TargetTime);
		
		const float DistanceHalf = Distance * 0.5f;

		const FVector DistanceBetweenA = (TargetLocation - _StartLocation) * 0.1f;
		const FVector DistanceBetweenB = (TargetLocation - _StartLocation) * 0.9f;
		const FVector DirectionBetween = (TargetLocation - _StartLocation).GetSafeNormal();
		const FVector RotatedDirection = DirectionBetween.RotateAngleAxis(AngleOffset, FVector::UpVector);
		const FVector RotatedDirection2 = DirectionBetween.RotateAngleAxis(90.0f, FVector::UpVector);

		const FVector P = (DirectionBetween + RotatedDirection).GetSafeNormal();
		const FVector ControlPointA = _StartLocation + RotatedDirection2 * AngleOffset;
		const FVector ControlPointB = TargetLocation + RotatedDirection2 * AngleOffset;

		Internal_Move(_StartLocation, ControlPointA, ControlPointB, TargetLocation, OutMovement, bDebugDraw);
	}

	private void Internal_Move(FVector Origin, FVector ControlPointA, FVector ControlPointB, FVector Destination, FCymbalMovementOutput& OutMovement, bool bDebugDraw = false)
	{
		_LastLocation = _CurrentLocation;
		const FVector NewLocation = Math::GetPointOnCubicBezierCurve(Origin, ControlPointA, ControlPointB, Destination, _Elapsed / _TargetTime);
		OutMovement.Location = _CurrentLocation = NewLocation;
		OutMovement.LastLocation = _LastLocation;
		OutMovement.MovementDelta = _LastLocation - OutMovement.Location;
		OutMovement.Rotation = (NewLocation - _LastLocation).Rotation();

#if TEST
		if(bDebugDraw)
		{
			DebugDrawMovement(Origin, ControlPointA, ControlPointB, Destination);
		}
#endif // TEST
	}

	private void DebugDrawMovement(FVector Origin, FVector ControlPointA, FVector ControlPointB, FVector Destination)
	{
		const float Chunk = 0.01f;
		System::DrawDebugSphere(ControlPointA, 200.0f, 12, FLinearColor::Blue);
		System::DrawDebugSphere(ControlPointB, 200.0f, 12, FLinearColor::Red);

		FVector PrevPoint = Math::GetPointOnCubicBezierCurve(Origin, ControlPointA, ControlPointB, Destination, 0.0f);
		for(float Alpha = Chunk; Alpha <= 1.0f; Alpha += Chunk)
		{
			FVector CurrPoint = Math::GetPointOnCubicBezierCurve(Origin, ControlPointA, ControlPointB, Destination, Alpha);
			System::DrawDebugLine(PrevPoint, CurrPoint, FLinearColor::Green, 0, 10.0f);
			PrevPoint = CurrPoint;
		}
	}

	FVector GetLastLocation() const property { return _LastLocation; }
	FVector GetStartLocation() const property { return _StartLocation; }
	FVector GetTargetLocation() const property { return _TargetLocation; }
	float GetTargetTime() const property { return _TargetTime; }
	float GetAlphaCurrent() const property { return FMath::Clamp(_Elapsed / FMath::Max(_TargetTime, 0.1f), 0.0f, 1.0f); }
	bool HasReachedLocation() const { return _Elapsed >= _TargetTime; }

	// Returns the direction from start location to end location.
	FVector GetMovementDirection() const property
	{
		return (_StartLocation - _TargetLocation).GetSafeNormal();
	}
}
