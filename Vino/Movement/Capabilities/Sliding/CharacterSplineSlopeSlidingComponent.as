import Peanuts.Spline.SplineComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Sliding.SplineSlopeSlidingSettings;
import Vino.Movement.Capabilities.Sliding.SlopeSlidingSplineComponent;

class UCharacterSlopeSlideComponent : UActorComponent
{
	UPROPERTY()
	USlopeSlidingSplineComponent GuideSpline = nullptr;

	FSplineSlopeSlidingSettings SlidingSettings;

	UPROPERTY()
	FHazeAcceleratedFloat SplineSideAccelerator;

	UPROPERTY()
	FHazeAcceleratedFloat SplineDirectionAccelerator;

	UPROPERTY()
	float CurrentDistanceAlongSpline = 0.f;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}

	void GetCurrentDirectionAlongSpline(const UHazeMovementComponent MoveComp, FVector& OutSplineDirection, FVector& OutSplineRightVector, bool bUseTheFloorHit = false)
	{
		CurrentDistanceAlongSpline = GuideSpline.GetDistanceAlongSplineAtWorldLocation(MoveComp.OwnerLocation);
		OutSplineDirection = GuideSpline.GetTangentAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		OutSplineDirection.Normalize();

		FVector CrossWith = MoveComp.WorldUp;

		if (MoveComp.PreviousDownHit.bBlockingHit && bUseTheFloorHit)
		{
			OutSplineDirection = OutSplineDirection.ConstrainToPlane(MoveComp.PreviousDownHit.Normal).GetSafeNormal();
			CrossWith = MoveComp.PreviousDownHit.Normal;
		}

		OutSplineRightVector = CrossWith.CrossProduct(OutSplineDirection);
	}

	float CalculateSpeedInSplineDirection(const UHazeMovementComponent MoveComp, FVector SplineDirection, FVector InputVector, float DeltaTime)
	{
		USplineSlopeSlidingForwardSpeedSettings Settings = USplineSlopeSlidingForwardSpeedSettings::GetSettings(PlayerOwner);

		float TargetSpeed = Settings.NeutralSpeed;
		FVector ConstrainedInput = InputVector.ConstrainToDirection(SplineDirection);
		
		if (!ConstrainedInput.IsNearlyZero())
		{
			const float AmountOfInputInDirection = ConstrainedInput.DotProduct(SplineDirection);
			float DifToNeutral = 0.f;
			if (AmountOfInputInDirection > 0.f)
			{
				DifToNeutral = Settings.MaxForwardSpeed - Settings.NeutralSpeed;
			}
			else
			{
				DifToNeutral = (Settings.NeutralSpeed - Settings.MinForwardSpeed);
			}

			TargetSpeed += DifToNeutral * AmountOfInputInDirection;
		}

		SplineDirectionAccelerator.Value = FMath::Max(SplineDirectionAccelerator.Value, Settings.MinForwardSpeed);
		SplineDirectionAccelerator.AccelerateTo(TargetSpeed, Settings.AccelerationTime, DeltaTime);

		return SplineDirectionAccelerator.Value;
	}

	void SetForwardSpeed(float Speed)
	{
		SplineDirectionAccelerator.Value = Speed;
	}

	FVector CalculateSideVelocity(const UHazeMovementComponent MoveComp, FVector GuideRightVector, FVector InputVector, float DeltaTime, bool bDebugDraw)
	{		
		float SideInclinModifier = 0.f;
		if (MoveComp.PreviousDownHit.bBlockingHit)
		{
			const float SideInclince = MoveComp.WorldUp.DotProduct(GuideRightVector);
			if (FMath::Abs(SideInclince) > SlidingSettings.SideInclineActivationTreshold)
				SideInclinModifier = FMath::Clamp(SideInclince, -SlidingSettings.SideInclineMaxDot, SlidingSettings.SideInclineMaxDot);
		}

		USplineSlopeSlidingTurnSettings TurnSettings = USplineSlopeSlidingTurnSettings::GetSettings(PlayerOwner);

		float AccelerationTime = TurnSettings.DefaultSideAccelerationTime;

		float SideInputModifier = 0.f;
		if (!InputVector.IsNearlyZero())
		{
			SideInputModifier = InputVector.DotProduct(GuideRightVector);

			if (MoveComp.Velocity.DotProduct(InputVector) <= 0.f)
			{
				AccelerationTime = TurnSettings.SteeringTowardsOppositeSideAccelerationTime;
			}
		}

		float CombinedModifier = SideInputModifier - (SideInclinModifier * SlidingSettings.InclineEffectModifier);
		CombinedModifier = FMath::Clamp(CombinedModifier, -1.f, 1.f);
				
		float TargetSpeed = TurnSettings.MaxSideSpeed * CombinedModifier;

		// are we outside bounds
		TargetSpeed = HandleSideClamping(MoveComp, TargetSpeed, GuideRightVector, bDebugDraw);

		SplineSideAccelerator.AccelerateTo(TargetSpeed, AccelerationTime, DeltaTime);
		float SideSpeed = SplineSideAccelerator.Value;
		return GuideRightVector * SideSpeed;
	}

	float HandleSideClamping(const UHazeMovementComponent MoveComp, float WantedSpeed, FVector GuideRightVector, bool bDebugDraw)
	{
		const FVector ToSpline = (GuideSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World) - Owner.ActorLocation);				

		if (bDebugDraw)
			DebugDrawClamp(MoveComp, ToSpline, GuideRightVector);

		float DistanceFromSpline = ToSpline.Size();

		USplineSlopeSlidingTurnSettings TurnSettings = USplineSlopeSlidingTurnSettings::GetSettings(PlayerOwner);

		float CurrentStartClampingDistance = GuideSpline.GetClampStartingDistanceAtSplineDistance(CurrentDistanceAlongSpline);
		float CurrentMaxAllowedDistanceFromSpline = GuideSpline.GetMaxSideDistanceAtSplineDistance(CurrentDistanceAlongSpline);

		if (DistanceFromSpline > CurrentStartClampingDistance)
		{
			const float TargetDirection = FMath::Sign(WantedSpeed);
			const float BackToSplineDirection = FMath::Sign(ToSpline.GetSafeNormal().DotProduct(GuideRightVector));

			float TurnBackVelocity = (TurnSettings.MaxSideSpeed * -TargetDirection) * 0.5f;

			if (BackToSplineDirection == TargetDirection)
				return WantedSpeed;

			if (DistanceFromSpline < CurrentMaxAllowedDistanceFromSpline)
			{
				const float LerpDistance = CurrentMaxAllowedDistanceFromSpline - CurrentStartClampingDistance;
				const float CurrentLerpDistance = DistanceFromSpline - CurrentStartClampingDistance;
				const float LerpAlpha = 0.5f + (CurrentLerpDistance / LerpDistance) / 2.f;

				if (FMath::Sign(SplineSideAccelerator.Velocity) != BackToSplineDirection)
					SplineSideAccelerator.Velocity = 0.f;//FMath::Lerp(SplineSideAccelerator.Velocity, 0.f, LerpAlpha);

				if (FMath::Sign(SplineSideAccelerator.Value) != BackToSplineDirection)
					SplineSideAccelerator.Value = 0.f;//FMath::Lerp(SplineSideAccelerator.Value, 0.f, LerpAlpha);

				return FMath::Lerp(WantedSpeed, TurnBackVelocity, LerpAlpha);
			}
			else //(DistanceFromSpline >= CurrentMaxAllowedDistanceFromSpline)
			{
				//are we steering more out or neutral then steer back

				if (FMath::Sign(SplineSideAccelerator.Velocity) != BackToSplineDirection)
					SplineSideAccelerator.Velocity = 0.f;

				if (FMath::Sign(SplineSideAccelerator.Value) != BackToSplineDirection)
					SplineSideAccelerator.Value = 0.f;

				return TurnBackVelocity;
			}
		}

		return WantedSpeed;
	}

	void DebugDrawClamp(const UHazeMovementComponent MoveComp, FVector ToSpline, FVector GuideRightVector)
	{
		FVector SplinCurrentLocation = GuideSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		DrawClampArrow(MoveComp, SplinCurrentLocation, ToSpline, GuideRightVector);
		DrawClampArrow(MoveComp, SplinCurrentLocation, ToSpline, -GuideRightVector);
	}

	void DrawClampArrow(const UHazeMovementComponent MoveComp, FVector CurrentSplineLocation, FVector ToSpline, FVector DrawDirection)
	{
		FVector UpDirection = MoveComp.WorldUp;
		if (MoveComp.DownHit.bBlockingHit)
			UpDirection = MoveComp.DownHit.Normal;

		float CurrentStartClampingDistance = GuideSpline.GetClampStartingDistanceAtSplineDistance(CurrentDistanceAlongSpline);
		float CurrentMaxAllowedDistanceFromSpline = GuideSpline.GetMaxSideDistanceAtSplineDistance(CurrentDistanceAlongSpline);

		FVector DrawPosition = CurrentSplineLocation + UpDirection * 150.f;
		if (ToSpline.DotProduct(DrawDirection) > 0)
		{
			System::DrawDebugArrow(DrawPosition, DrawPosition + DrawDirection * CurrentMaxAllowedDistanceFromSpline, 5.f, FLinearColor::Blue);
		}
		else
		{
			System::DrawDebugSphere(DrawPosition + DrawDirection * CurrentStartClampingDistance, 25.f, 12, FLinearColor::Green);
			System::DrawDebugSphere(DrawPosition + DrawDirection * CurrentMaxAllowedDistanceFromSpline, 25.f, 12, FLinearColor::Red);
			
			FLinearColor DistanceFromSplineColor = FLinearColor::Green;
			if (ToSpline.Size() > CurrentMaxAllowedDistanceFromSpline)
			{
				DistanceFromSplineColor = FLinearColor::Red;
			}
			else if (ToSpline.Size() > CurrentStartClampingDistance)
			{
				DistanceFromSplineColor = FLinearColor::Blue;
			}

			FVector CurrentSidePosition = DrawPosition + DrawDirection * ToSpline.Size();
			System::DrawDebugArrow(DrawPosition, CurrentSidePosition, 5.f, DistanceFromSplineColor);

			float RemainingDistance = CurrentMaxAllowedDistanceFromSpline - ToSpline.Size();
			System::DrawDebugArrow(CurrentSidePosition, CurrentSidePosition + DrawDirection * RemainingDistance, 5.f, FLinearColor::Yellow);
		}
	}
}
