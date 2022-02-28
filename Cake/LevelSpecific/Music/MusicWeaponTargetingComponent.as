

struct FMusicWeaponTargetingOutput
{
	AActor HitActor;	// If trace was performed
	FVector Location;	// new location in world space
	FVector MovementDelta;
	FVector LastLocation;
	FRotator Rotation;
	bool bHitSomething = false; // if the trace was a blocking hit
}

class UMusicWeaponTargetingComponent : UActorComponent
{
	private FVector _TargetLocation;
	private FVector _StartLocation;
	private FVector _CurrentLocation;
	private FVector _LastLocation;

	private FVector _RandomDirection;

	private float _TargetTime = 0;

	private float _Elapsed = 0;

	private float TargetAngleOffset = 90.0f;
	private float AngleOffset = 0.0f;

	// Start movement with the intention of simple moving forward
	void StartTargeting(FVector StartLocation, FVector TargetLocation, float Speed, bool bFlipRandomDirection = false)
	{
		_StartLocation = _CurrentLocation = _LastLocation = StartLocation;
		_TargetLocation = TargetLocation;
		const float DistanceToTarget = FMath::Max(StartLocation.Distance(TargetLocation), 1.0f);
		const float DistanceHalf = DistanceToTarget * 0.5f;
		_TargetTime = (DistanceToTarget / Speed);
		//_TargetTime = _TargetTime * (1.0f + _TargetTime);
		_Elapsed = 0;

		const FVector DirectionTo = (TargetLocation - StartLocation).GetSafeNormal();

		FVector OffsetVector = DirectionTo.RotateAngleAxis(TargetAngleOffset, FVector::UpVector);
		System::DrawDebugLine(_StartLocation, _StartLocation + OffsetVector * DistanceHalf, FLinearColor::Red, 5, 10);

		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Game::GetCody());
		IgnoreActors.Add(Game::GetMay());

		const FVector EndLoc = _StartLocation + OffsetVector * DistanceHalf;
		FHitResult Hit;
		System::LineTraceSingle(_StartLocation, EndLoc, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::ForDuration, Hit, false);
		AngleOffset = TargetAngleOffset;
		if(Hit.bBlockingHit)
		{
			FVector ClosestPoint = Math::ProjectPointOnInfiniteLine(_StartLocation, DirectionTo, Hit.ImpactPoint);
			System::DrawDebugPoint(ClosestPoint, 10, FLinearColor::Blue, 5);


			const float AngularOffsetFraction = TargetAngleOffset * (Hit.Distance / DistanceHalf);
			PrintToScreen("AngularOffsetFraction " + AngularOffsetFraction, 5);
			AngleOffset = AngularOffsetFraction;
		}

		if(!bFlipRandomDirection)
		{
			//_RandomDirection = FMath::VRand() * 0.15f;
		}
		//else
			//_RandomDirection *= -1.0f;
	}

	void StartTargetingWithTime(FVector StartLocation, FVector TargetLocation, float TargetTime)
	{
		_StartLocation = _CurrentLocation = _LastLocation = StartLocation;
		_TargetLocation = TargetLocation;
		_TargetTime = TargetTime;
		_Elapsed = 0;

		const FVector DirectionTo = (TargetLocation - StartLocation).GetSafeNormal();
		_RandomDirection = FMath::VRand() * 0.25f;
	}

	void Move(float DeltaTime, FVector TargetLocation, FMusicWeaponTargetingOutput& OutMovement, bool bTrace = false)
	{
		_LastLocation = _CurrentLocation;
		const FVector ToTarget = TargetLocation - _StartLocation;
		const FVector DirectionToTarget = ToTarget.GetSafeNormal();
		const float Fraction = _Elapsed / _TargetTime;
		_Elapsed = FMath::Min(_Elapsed + DeltaTime, _TargetTime);
		OutMovement.Rotation = DirectionToTarget.Rotation();
		OutMovement.Location = _StartLocation + ToTarget * Fraction;
		OutMovement.LastLocation = _LastLocation;
		OutMovement.MovementDelta = _LastLocation - OutMovement.Location;
	}

	void MoveWithBezier(float DeltaTime, FVector TargetLocation, FMusicWeaponTargetingOutput& OutMovement)
	{
		_Elapsed = FMath::Min(_Elapsed + DeltaTime, _TargetTime);
		_LastLocation = _CurrentLocation;
		const float Distance = (TargetLocation - _StartLocation).Size() * 0.5f;
		const FVector DistanceBetweenA = (TargetLocation - _StartLocation) * 0.10f;
		const FVector DistanceBetweenB = (TargetLocation - _StartLocation) * 0.55f;
		const FVector DirectionBetween = (TargetLocation - _StartLocation).GetSafeNormal();
		const FVector RotatedDirection = DirectionBetween.RotateAngleAxis(AngleOffset, FVector::UpVector);
		const FVector P = (DirectionBetween + RotatedDirection).GetSafeNormal();
		const FVector ControlPointA = (_StartLocation + DistanceBetweenA) + (P * Distance);
		const FVector ControlPointB = (_StartLocation + DistanceBetweenB) + (P * Distance);
		//DistanceBetween.
		const FVector NewLocation = Math::GetPointOnCubicBezierCurve(_StartLocation, ControlPointA, ControlPointB, TargetLocation, _Elapsed / _TargetTime);
		OutMovement.Rotation = (NewLocation - _LastLocation).GetSafeNormal().Rotation();
		OutMovement.Location = NewLocation;
		OutMovement.LastLocation = _LastLocation;
		OutMovement.MovementDelta = _LastLocation - OutMovement.Location;
		const float Chunk = 0.01f;

		
		//PrintToScreen("Distance " + Distance);


		System::DrawDebugSphere(ControlPointA, 200.0f, 12, FLinearColor::Blue);
		System::DrawDebugSphere(ControlPointB, 200.0f, 12, FLinearColor::Red);

		FVector PrevPoint = Math::GetPointOnCubicBezierCurveConstantSpeed(_StartLocation, ControlPointA, ControlPointB, TargetLocation, 0.0f);
		for(float Alpha = Chunk; Alpha <= 1.0f; Alpha += Chunk)
		{
			FVector CurrPoint = Math::GetPointOnCubicBezierCurveConstantSpeed(_StartLocation, ControlPointA, ControlPointB, TargetLocation, Alpha);

			System::DrawDebugLine(PrevPoint, CurrPoint, FLinearColor::Green, 0, 10.0f);

			PrevPoint = CurrPoint;
		}

		
	}

	FVector GetLastLocation() const { return _LastLocation; }
	bool HasReachedLocation() const { return _Elapsed >= _TargetTime; }
}