class ACuckooBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Base;

	FVector Input = FVector::ZeroVector;
	float HorizontalSpeed;
	float HorizontalSpeedTarget;
	float MaxUpPitch = 180.f;
	float MaxDownPitch = 85.f;
	float AllowedUpPitch;
	float CurrentPitch;
	float TargetPitch;
	float MaxHorizontalSpeed = 5000.f;
	float HorizontalSpeedFlatMod = 2500.f;
	float SpeedInterpolationSpeed;

	UFUNCTION(BlueprintOverride)
	void Tick(float Delta)
	{
		Input.Y = Input.Y * -1.f;
		CurrentPitch = ActorRotation.Pitch;
		float SpeedFlatMod;
		if (CurrentPitch < TargetPitch)
			SpeedFlatMod = 0.1f;
		else
			SpeedFlatMod = 1.f;

		if (ActorForwardVector.DotProduct(FVector::UpVector * -1.f) < 0.)
		{
			HorizontalSpeedTarget = 0.f;
			SpeedInterpolationSpeed = (ActorForwardVector.DotProduct(FVector::UpVector * 1.f) / 8) + SpeedFlatMod;
		}
		else
		{
			HorizontalSpeedTarget = ActorForwardVector.DotProduct(FVector::UpVector * -1.f) * MaxHorizontalSpeed;
			SpeedInterpolationSpeed = (ActorForwardVector.DotProduct(FVector::UpVector * -1.f) / 8) + SpeedFlatMod;
		}

		HorizontalSpeed = FMath::FInterpTo(HorizontalSpeed, HorizontalSpeedTarget, Delta, SpeedInterpolationSpeed);
		AllowedUpPitch = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MaxHorizontalSpeed * 0.65), FVector2D(-35.f, MaxUpPitch), HorizontalSpeed);

		if (Input.Y == 0)
		{
			TargetPitch = ActorRotation.Pitch;
		}
		else if (Input.Y < 0)
		{
			TargetPitch = MaxUpPitch * Input.Y;
		}
		else
		{
			TargetPitch = MaxDownPitch * Input.Y;
		}
		TargetPitch = FMath::Clamp(TargetPitch, -MaxDownPitch, AllowedUpPitch);

		float DistanceFromGroundFlatMod;
		float DistanceFromGround;
		TArray<AActor> ActorsToIgnore;
		FHitResult HitResult;
		System::LineTraceSingle(ActorLocation, ActorLocation + ((FVector::UpVector * -1) * 750.f), ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);
		if(HitResult.bBlockingHit)
		{
			DistanceFromGround = (ActorLocation - HitResult.Location).Size();
		}
		else
		{
			DistanceFromGround = 750.f;
		}

		DistanceFromGroundFlatMod = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 750.f), FVector2D(2.f, 0.f), DistanceFromGround);

		float FlatMod = FMath::GetMappedRangeValueClamped(FVector2D(-MaxDownPitch, MaxUpPitch), FVector2D(HorizontalSpeedFlatMod, 0.f), CurrentPitch);
		float RotationSpeed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MaxHorizontalSpeed + HorizontalSpeedFlatMod), FVector2D(1.f, 0.45f), HorizontalSpeed + FlatMod);

		FRotator NewRotation = ActorRotation;
		NewRotation.Yaw = NewRotation.Yaw + (Input.X * 90.f);
		NewRotation.Roll = Input.X * 60.f;

		NewRotation = FMath::RInterpTo(ActorRotation, FRotator(TargetPitch, NewRotation.Yaw, NewRotation.Roll), Delta, RotationSpeed + DistanceFromGroundFlatMod);
		SetActorRotation(NewRotation);
		SetActorLocation((ActorForwardVector * ((HorizontalSpeed + FlatMod) * Delta)) + ActorLocation);
	}

	void DrawDebugMaxPitch()
	{
		FVector ArrowOffsetVector = ActorForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FQuat MyQuat = FQuat(ArrowOffsetVector.CrossProduct(FVector::UpVector).GetSafeNormal(), AllowedUpPitch * DEG_TO_RAD);
		FVector RotatedVector = MyQuat.RotateVector(ArrowOffsetVector);
		System::DrawDebugArrow(ActorLocation, ActorLocation + (RotatedVector * 150.f));
	}

	UFUNCTION(BlueprintEvent)
	void FlapWings()
	{
		SpeedBoost();
	}

	UFUNCTION()
	void SpeedBoost()
	{
		HorizontalSpeed += 2000.f;
	}
}