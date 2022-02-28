import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineActor;

event void FOnReachedSplineEnd(bool bForward);
event void FOnSplineTransition(UConnectedHeightSplineFollowerComponent ConnectedHeightSplineFollowerComponent, bool bForward);
event void FOnFootPrintOverlap(UConnectedHeightSplineFollowerComponent ConnectedHeightSplineFollowerComponent, UConnectedHeightSplineComponent OverlappingSpline, bool bForward);
event void FOnGrounded();

class UConnectedHeightSplineFollowerComponent : UActorComponent
{
	UPROPERTY()
	AConnectedHeightSplineActor SplineActor;

	UConnectedHeightSplineComponent Spline;

	UConnectedHeightSplineComponent PreviousSpline;

	UPROPERTY()
	float Offset = 0.f;

	UPROPERTY()
	float DistanceOnSpline = 0.f;

	float DistanceOnSplineFromCurve = DistanceOnSpline;

	UPROPERTY()
	float TotalDistance = 0.f;

	UPROPERTY()
	float Height = 0.f;

	UPROPERTY()
	float FootPrintRadius = 100.f;

	UPROPERTY()
	int FootPrintSamples = 4;

	UPROPERTY()
	FVector GroundNormal;
	
	UPROPERTY()
	float GroundZ = 0.f;

	UPROPERTY()
	FTransform Transform;

	UPROPERTY()
	FTransform SplineTransform;

	FVector Velocity;
	FVector AngularVelocity;

	UPROPERTY()
	bool bUseHeight = false;

	UPROPERTY()
	bool bIsGrounded = true;

	bool bForwardDirection = true;

	UPROPERTY()
	bool bGenerateOverlapEvents = false;

	bool bForwardOverlap = false;
	bool bBackwardOverlap = false;

	float LastUpdateDistanceOnSpline = 0.f;
	float LastUpdateGroundZ = 0.f;

	UPROPERTY()
	bool bUseActorForwardDirection = false;

	UPROPERTY()
	FOnReachedSplineEnd OnReachedSplineEnd;

	UPROPERTY()
	FOnSplineTransition OnSplineTransition;

	UPROPERTY()
	FOnFootPrintOverlap OnFootPrintOverlap;

	UPROPERTY()
	FOnGrounded OnGrounded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetSplineActorSpline();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	}

	UFUNCTION()
	void SetSplineActorSpline()
	{
		if (SplineActor == nullptr)
		{
			Spline = nullptr;
			return;
		}

		Spline = SplineActor.ConnectedHeightSplineComponent;
	}

	/* Functions for setting/adding Distance, Offset and Height */
	UFUNCTION()
	void AddDistance(float DistanceToAdd)
	{
		bForwardDirection = (DistanceToAdd >= 0.f);

		DistanceOnSpline += DistanceToAdd;
		TotalDistance += FMath::Abs(DistanceToAdd);

		Update(Owner.ActorDeltaSeconds);
	}

	UFUNCTION()
	void AddOffset(float OffsetToAdd)
	{
		Offset += OffsetToAdd;

		Update(Owner.ActorDeltaSeconds);
	}

	UFUNCTION()
	void AddHeight(float HeightToAdd)
	{
		Height += HeightToAdd;

		Update(Owner.ActorDeltaSeconds);
	}

	UFUNCTION()
	void AddMovementVector(FVector DeltaMovement)
	{
		bForwardDirection = (DeltaMovement.X >= 0.f);
		TotalDistance += FMath::Abs(DeltaMovement.X);

		DistanceOnSpline += DeltaMovement.X;
		Offset += DeltaMovement.Y;
		Height += DeltaMovement.Z;

		Update(Owner.ActorDeltaSeconds);
	}

	UFUNCTION()
	void AddMovementVectorWithTime(FVector DeltaMovement, float DeltaTime)
	{
		if (DeltaTime <= 0.00001f)
			return;

		bForwardDirection = (DeltaMovement.X >= 0.f);
		TotalDistance += FMath::Abs(DeltaMovement.X);

		DistanceOnSpline += DeltaMovement.X;
		Offset += DeltaMovement.Y;
		Height += DeltaMovement.Z;

		Update(DeltaTime);
	}

	UFUNCTION()
	void SetSplineDistance(float NewDistance)
	{
		DistanceOnSpline = NewDistance;

		Update();
	}

	UFUNCTION()
	void SetSplineOffset(float NewOffset)
	{
		Offset = NewOffset;

		Update();
	}

	UFUNCTION()
	void SetDistanceAndOffset(float NewDistance, float NewOffset)
	{
		DistanceOnSpline = NewDistance;
		Offset = NewOffset;

		Update();
	}

	UFUNCTION()
	void SetDistanceAndOffsetAtWorldLocation(FVector WorldLocation)
	{
		float Distance = Spline.GetDistanceAlongSplineAtWorldLocation(WorldLocation);
		FTransform TransformAtDistance = Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World, false);
		float RelativeOffset = TransformAtDistance.InverseTransformPosition(WorldLocation).Y;

		DistanceOnSpline = Distance;
		Offset = RelativeOffset;
		
		DistanceOnSplineFromCurve = DistanceOnSpline;
	//	SetDistanceAndOffset(Distance, RelativeOffset);
	}

	UFUNCTION()
	void ClearVelocity()
	{
	//	Velocity = FVector::ZeroVector; // Velocity will be updated in Update... this has no effect?

		Update(Owner.ActorDeltaSeconds);
	}	

	/* Update SplineFollower Transform and States */
	void Update(float DeltaTime = 0.f)
	{
		if (!MoveOnValidSpline())
			return;

		if (bGenerateOverlapEvents)
			UpdateOverlaps();

		// Use DistanceCurve to manipulate the distance on the spline (Overlaps might break)
		DistanceOnSplineFromCurve = DistanceOnSpline;

		if (Spline.DistanceCurve != nullptr)
		{
			float Time = DistanceOnSpline / Spline.SplineLength;
			DistanceOnSplineFromCurve = Spline.DistanceCurve.GetFloatValue(Time) * Spline.SplineLength;
		}
	
		FTransform TransformAtDistance = Spline.GetTransformAtDistanceAlongSpline(DistanceOnSplineFromCurve, ESplineCoordinateSpace::World, true);

		float SplineWidth = TransformAtDistance.Scale3D.Y * Spline.BaseWidth;

		Offset = FMath::Clamp(Offset, -SplineWidth, SplineWidth);

		// Get Footprint values
		if (!Spline.bIsGap)
			Spline.GetNormalAndZFromFootPrintAtDistanceAndOffset(DistanceOnSplineFromCurve, Offset, GroundZ, GroundNormal, FootPrintRadius, FootPrintSamples);
		else
			GroundZ = Spline.GapZLevel;

		if (!Spline.bIsGap)
			Height = bUseHeight ? FMath::Max(Height, GroundZ) : GroundZ;

		if (CanStepDown())
			Height = GroundZ;

		// OnGrounded Event
		if (!bIsGrounded && Height <= GroundZ)
			OnGrounded.Broadcast();

		// Set grounded state
		bIsGrounded = Height <= GroundZ;

		// Calculate Location
		FVector Location = TransformAtDistance.Location
						 + TransformAtDistance.Rotation.RightVector * Offset
						 + TransformAtDistance.Rotation.UpVector * Height;

		// Calculate Velocity
		if (DeltaTime > 0.f)
			Velocity = (Location - Transform.Location) / DeltaTime;
		else
			Velocity = FVector::ZeroVector;

		// Calculate Rotation
		FVector Direction = bUseActorForwardDirection ? Owner.ActorForwardVector : Velocity.GetSafeNormal();
		FRotator Rotation = bIsGrounded ? FRotator::MakeFromXZ(Direction, GroundNormal) : FRotator::MakeFromXZ(Direction, TransformAtDistance.Rotation.UpVector);

		// Set the Rotation to be in spline direction if there was no DeltaTime (Teleport)
		if (DeltaTime == 0.f)
			Rotation = FRotator::MakeFromXZ(TransformAtDistance.Rotation.ForwardVector, GroundNormal);

		// Calculate AngularVelocity
		if (DeltaTime > 0.f)
			AngularVelocity = Transform.Rotation.ForwardVector.CrossProduct(Direction) / DeltaTime;
		else
			AngularVelocity = FVector::ZeroVector;

		// Update SplineFollower Transform
		Transform.SetLocation(Location);
		Transform.SetRotation(Rotation);
		Transform.SetScale3D(TransformAtDistance.Scale3D);

		// Update SplineTransform
		SplineTransform = TransformAtDistance;

		// Set LastUpdate Values for StepDown
		LastUpdateDistanceOnSpline = DistanceOnSpline;
		LastUpdateGroundZ = GroundZ;

		// Debug
	//	System::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Velocity * 1000.f, FLinearColor::Green, 0.f, 20.f);	
	//	PrintToScreen("" + Name + " Velocity: " + Velocity);
	}

	void UpdateOverlaps()
	{
		float TempOffset = Offset;

		if (DistanceOnSpline + FootPrintRadius > Spline.SplineLength)
		{
			TempOffset = Offset;		

	//		if (!bForwardOverlap)
				OnFootPrintOverlap.Broadcast(this, Spline.GetNextSpline(TempOffset, true), true);

	//		bForwardOverlap = true;			
		}
	//	else
	//		bForwardOverlap = false;

		if (DistanceOnSpline - FootPrintRadius < 0.f)
		{
			TempOffset = Offset;

	//		if (!bBackwardOverlap)
				OnFootPrintOverlap.Broadcast(this, Spline.GetNextSpline(TempOffset, false), false);			
			
	//		bBackwardOverlap = true;
		}
	//	else
	//		bBackwardOverlap = false;

	}

	bool MoveOnValidSpline()
	{
		if (Spline == nullptr)
			return false;

		PreviousSpline = Spline;

		if (DistanceOnSpline > Spline.SplineLength)
		{
			DistanceOnSpline -= Spline.SplineLength;

			if (!Spline.IsClosedLoop())
			{
				Spline = Spline.GetNextSpline(Offset, true);
				
				if (Spline == nullptr)
				{
					Spline = PreviousSpline;
					DistanceOnSpline = Spline.SplineLength;
					OnReachedSplineEnd.Broadcast(true);
					return false;
				}

				OnSplineTransition.Broadcast(this, true);
			}

		}
		else if (DistanceOnSpline < 0.f)
		{
			if (!Spline.IsClosedLoop())		
			{	
				Spline = Spline.GetNextSpline(Offset, false);	
			
				if (Spline == nullptr)
				{
					Spline = PreviousSpline;
					DistanceOnSpline = 0.f;
					OnReachedSplineEnd.Broadcast(false);				
					return false;
				}
				
				OnSplineTransition.Broadcast(this, false);
			}
		
			DistanceOnSpline +=	Spline.SplineLength;
			
		}

		return true;
	}

	bool CanStepDown()
	{
		float StepDistance = DistanceOnSpline - LastUpdateDistanceOnSpline;
		float StepHeight = GroundZ - LastUpdateGroundZ;
		float StepRatio = 0.f;

		if (StepDistance != 0.f)
			StepRatio = StepHeight / StepDistance;

	//	PrintToScreen("StepRatio: " + StepRatio);

		return (StepRatio > -0.5f && bIsGrounded);
	}

	FTransform GetSplineWorldTransform()
	{
		Spline.GetNormalAndZFromFootPrintAtDistanceAndOffset(DistanceOnSplineFromCurve, Offset, GroundZ, GroundNormal, FootPrintRadius, FootPrintSamples);

		FTransform TransformAtDistance = Spline.GetTransformAtDistanceAlongSpline(DistanceOnSplineFromCurve, ESplineCoordinateSpace::World, true);

		FVector Location = TransformAtDistance.Location
						 + TransformAtDistance.Rotation.RightVector * Offset
						 + TransformAtDistance.Rotation.UpVector * GroundZ;

		TransformAtDistance.Location = Location;
		TransformAtDistance.Rotation = FRotator::MakeFromZ(GroundNormal).Quaternion();

		return TransformAtDistance;
	}

	FTransform GetSplineTransform(bool bUseOffset = false)
	{
		if (Spline == nullptr)
			return FTransform::Identity;

		FTransform PointTransform = Spline.GetTransformAtDistanceAlongSpline(DistanceOnSplineFromCurve, ESplineCoordinateSpace::World, true);
		
		if (bUseOffset)
			PointTransform.Location = PointTransform.Location + PointTransform.Rotation.RightVector * Offset;

		return PointTransform;
	}

}