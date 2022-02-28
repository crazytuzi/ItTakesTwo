import Vino.Camera.Components.CameraUserComponent;

// Component that will move smoothly away from user when they get too close.
// Useful when you don't want a camera to end up right above user etc.
class UCameraPushAwayFromUserComponent : UHazeCameraParentComponent
{
	// How fast we reach target velocity when pushing away from user. Lower values means harder acceleration.
	UPROPERTY()
	float PushAccelerationDuration = 0.5f;

	// At this distance we will use full acceleration
	UPROPERTY()
	float MinDistance = 200.f;

	// At this distance acceleration will be zero
	UPROPERTY()
	float MaxDistance = 500.f;

	// Scale of push in user base space axes. Default is (1,1,0) so we'll avoid the player in the xy-plane only.
	UPROPERTY()
	FVector AxisFreedomFactor = FVector(1.f, 1.f, 0.f);

	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;
	FHazeAcceleratedVector Velocity;
	
	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent CameraUser, EHazeCameraState PreviousState)
	{
		User = Cast<UCameraUserComponent>(CameraUser);
		PlayerUser = Cast<AHazePlayerCharacter>(CameraUser.Owner);
		if(PreviousState == EHazeCameraState::Inactive)
		{
			Snap();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		Velocity.SnapTo(GetTargetVelocity());
		FVector FromUser = GetConstrainedWorldToLocal(WorldLocation - PlayerUser.FocusLocation);
		if (FromUser.SizeSquared() < FMath::Square(MinDistance))
			SetWorldLocation(PlayerUser.FocusLocation + User.BaseRotation.RotateVector(FromUser).GetSafeNormal() * MinDistance);  
		Update(0);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaTime)
	{
		Velocity.AccelerateTo(GetTargetVelocity(), PushAccelerationDuration, DeltaTime);
		SetWorldLocation(WorldLocation + User.BaseRotation.RotateVector(Velocity.Value) * DeltaTime);
	}

	FVector GetConstrainedWorldToLocal(FVector WorldVector)
	{
		FVector LocalFromUser = User.BaseRotation.Inverse().RotateVector(WorldVector);
		return LocalFromUser * AxisFreedomFactor;
	}

	FVector GetTargetVelocity()
	{
		FVector FromUser = GetConstrainedWorldToLocal(WorldLocation - PlayerUser.FocusLocation);
		float DistSqr = FromUser.SizeSquared();
		if (DistSqr > FMath::Square(MaxDistance))
			return FVector::ZeroVector;
		
		// Get users current speed toward us
		FVector PushDir = FromUser.GetSafeNormal();
		FVector LocalMoveVelocity = GetConstrainedWorldToLocal(PlayerUser.ActualVelocity);
		float Speed = FMath::Max(0.f, LocalMoveVelocity.DotProduct(PushDir)); 

		// Tweak target speed based on distance 
		float MinDistSqr = FMath::Square(MinDistance);
		float MaxDistSqr = FMath::Square(MaxDistance);
		Speed *= FMath::GetMappedRangeValueClamped(FVector2D(MinDistSqr, MaxDistSqr), FVector2D(1.f, 0.f), DistSqr);

		// When past min..max midpoint, we should always push away with some speed.
		float MidDistSqr = FMath::Square((MinDistance + MaxDistance) * 0.5f);
		float MinSpeed = FMath::GetMappedRangeValueClamped(FVector2D(MinDistSqr, MidDistSqr), FVector2D(100.f, 0.f), DistSqr);
		if (Speed < MinSpeed)
			Speed = MinSpeed;

		return PushDir * Speed;
	}
}
