import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineFollowerComponent;

class USnowFolkMovementComponent : UActorComponent
{
	UPROPERTY(NotVisible)
	UConnectedHeightSplineFollowerComponent SplineFollowerComp;

	UPROPERTY(NotVisible)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(Category = "Snowfolk|Movement")
	bool bIsSkating;

	// Controlling going back-and-forth on the spline
	UPROPERTY(Category = "Snowfolk|Movement")
	float Freq;
	UPROPERTY(Category = "Snowfolk|Movement")
	float Phase;
	UPROPERTY(Category = "Snowfolk|Movement")
	float Amp;

	UPROPERTY(Category = "Snowfolk|Movement")
	float LerpInTime;

	UPROPERTY(Category = "Snowfolk|Movement")
	bool bLerpInSpeed;
	float LerpInTimer;

	const float SplineTransitionLerpTime = 5.f;

	UPROPERTY(Category = "Snowfolk|Movement")
	float BaseSpeed;
	float Speed;

	UPROPERTY(Category = "Snowfolk|Movement")
	float CustomLength;

	UPROPERTY(Category = "Snowfolk|Movement")
	float ReachSplineEndTime;
	float ReachSplineEndTimeLeft;

	UPROPERTY(Category = "Snowfolk|Movement")
	float StartDistance;
	float ExtraDistance;

	UPROPERTY(Category = "Snowfolk|Movement")
	float StartOffset;
	float ExtraOffset;

	UPROPERTY(Category = "Snowfolk|Movement")
	bool bAlwaysUpright;

	bool bIsSnowfolkVisible = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrumbComp = UHazeCrumbComponent::Get(Owner);

		SplineFollowerComp = UConnectedHeightSplineFollowerComponent::Get(Owner);
		SplineFollowerComp.OnReachedSplineEnd.AddUFunction(this, n"HandleReachedSplineEnd");
		SplineFollowerComp.OnSplineTransition.AddUFunction(this, n"HandleSplineTransition");

		Speed = BaseSpeed;

		// Initial Setup
		if (SplineFollowerComp.Spline != nullptr)
		{
			// Sets BaseSpeed to reach end of Spline at set Time
			if (ReachSplineEndTime > 0.f)
			{			
				BaseSpeed = (SplineFollowerComp.Spline.SplineLength + ExtraDistance) / ReachSplineEndTime;
				ReachSplineEndTimeLeft = ReachSplineEndTime;
			}

			Speed = BaseSpeed;
			LerpInTimer = LerpInTime;

			StartDistance = SplineFollowerComp.DistanceOnSpline;
			StartOffset = SplineFollowerComp.Offset;
			ExtraDistance = SplineFollowerComp.Spline.SplineLength - StartDistance;
		}
	}

	void Move(float DeltaTime)
	{
		if (HasControl())
		{
			// Adjust speed to reach in time
			if (ReachSplineEndTimeLeft > 0.f && ReachSplineEndTime > 0.f)
			{
				ReachSplineEndTimeLeft -= DeltaTime;
				BaseSpeed = (SplineFollowerComp.Spline.SplineLength + ExtraDistance - SplineFollowerComp.TotalDistance) / ReachSplineEndTimeLeft;
			}
			else if (ReachSplineEndTime > 0.f)
			{
				BaseSpeed = (SplineFollowerComp.Spline.SplineLength + ExtraDistance) / ReachSplineEndTime;
			}

			float Alpha = 0.f;
			if (LerpInTimer > 0.f)
			{
				LerpInTimer -= DeltaTime;
				Alpha = FMath::Clamp(LerpInTimer / LerpInTime, 0.f, 1.f);

				if (bLerpInSpeed)
					Speed = BaseSpeed * (1.f - Alpha);
			}

			float SplineOffset = SplineFollowerComp.DistanceOnSpline + Speed * DeltaTime;
			float DeltaOffset = SplineFollowerComp.Spline.GetTransformAtDistanceAlongSpline(SplineOffset, ESplineCoordinateSpace::World, true).Scale3D.Y * 
				GetOffsetFromSine(SplineOffset) * SplineFollowerComp.Spline.BaseWidth;
			DeltaOffset = FMath::Lerp(DeltaOffset + ExtraOffset, StartOffset, Alpha) - SplineFollowerComp.Offset;

			SplineFollowerComp.AddMovementVectorWithTime(FVector(Speed * DeltaTime, DeltaOffset, 0.f), DeltaTime);

			CrumbComp.SetCustomCrumbVector(CurrentTransform.Location);
			CrumbComp.SetCustomCrumbRotation(CurrentTransform.Rotator());
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized Params;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, Params);

			SplineFollowerComp.Transform.Location = Params.CustomCrumbVector;
			SplineFollowerComp.Transform.Rotation = Params.CustomCrumbRotator.Quaternion();

			if (DeltaTime != 0.f)
			{
				FVector Direction = SplineFollowerComp.bUseActorForwardDirection ? Owner.ActorForwardVector : SplineFollowerComp.Velocity.GetSafeNormal();
				SplineFollowerComp.Velocity = (SplineFollowerComp.Transform.Location - Owner.ActorLocation) / DeltaTime;
				SplineFollowerComp.AngularVelocity = SplineFollowerComp.Transform.Rotation.ForwardVector.CrossProduct(Direction) / DeltaTime;
			}
		}
	}

	UFUNCTION()
	void HandleReachedSplineEnd(bool bForward)
	{
		// Invert direction
		Speed *= -1.f;
		BaseSpeed *= -1.f;
	}

	UFUNCTION()
	void HandleSplineTransition(UConnectedHeightSplineFollowerComponent ConnectedHeightSplineFollowerComponent, bool bForward)
	{
		// Smooth offset when doing transitions
		LerpInTime = SplineTransitionLerpTime;
		StartOffset = SplineFollowerComp.Offset;
		LerpInTimer = SplineTransitionLerpTime;
	}

	void Reset()
	{
		SplineFollowerComp.SetDistanceAndOffset(StartDistance, StartOffset);

		LerpInTimer = LerpInTime;
		ReachSplineEndTimeLeft = ReachSplineEndTime;
	}

	float GetOffsetFromSine(float Distance)
	{
		float SplineLength = CustomLength > 0.f ? CustomLength : SplineFollowerComp.Spline.SplineLength;
		float SineOffset = FMath::Sin((Freq * PI * 2.f / SplineLength) * (Distance + Phase)) * Amp;

		return SineOffset;
	}

	UFUNCTION(BlueprintPure)
	FTransform GetCurrentTransform() property
	{
		FTransform Transform = SplineFollowerComp.Transform;
		if (bAlwaysUpright)
			Transform.Rotation = Math::MakeQuatFromZX(FVector::UpVector, Transform.Rotation.ForwardVector);

		return Transform;
	}
}