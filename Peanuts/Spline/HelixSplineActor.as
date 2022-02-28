import Peanuts.Spline.SplineActor;

class AHelixSplineActor : ASplineActor 
{
	// y = radius, x = height.
	UPROPERTY(AdvancedDisplay, Category = "Helix Properties")
	FRuntimeFloatCurve HelixCurvature;

	// Will automatically update the spline on construction script. 
	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	bool bAutoGenerateHelixWhileEditing = true;

	// Mirrors it. It will generate the helix in the clockwise (rotational) direction.
	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	bool bCounterClockwise = false;

	// The spline structure will not change only what is considered backwards and forwards
	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	bool bFlipDirection= false;
	bool bPreviousFlipDirection = false;

	/* Will be clamped to [0, 360] degree range internally.*/
	UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "3", UIMin = "3", ClampMax = "360", UIMax = "360"))
	int PointsPerTurn = 16;

	UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "0", UIMin = "0"))
	float Height = 3000.f;

	UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "0", UIMin = "0"))
	float Radius = 300.f;

	UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "1", UIMin = "1"))
	int Turns = 8;

	float Pitch = 0.f;
	float StepSize_Angular = 0.f;
	float StepSize_Pitch = 0.f;
	int TotalIterations = 0;
	float MaxPaddingFromCenter = 0.f;

	FVector CompLocation = FVector::ZeroVector;
	FVector SpiralCenter = FVector::ZeroVector;
	FQuat CompQuat = FQuat::Identity;
	TArray<FVector> SpiralParticleLocations;
	TArray<FSpiralParticle> SpiralParticles;

	UFUNCTION(BlueprintOverride)
	void PostEditChangeProperties()
	{
		if (bAutoGenerateHelixWhileEditing == false)
			return;

		InitData();
		GenerateHelixData();
		UpdateSpline();

		// DEBUG
		if(bFlipDirection != bPreviousFlipDirection)
		{
			bPreviousFlipDirection = bFlipDirection;
#if EDITOR	
			System::FlushPersistentDebugLines();
			System::DrawDebugArrow(
				SpiralParticleLocations[0],
				SpiralParticleLocations.Last(),
				Height * Radius * 0.5f,
				FLinearColor::Yellow,
				3.f,
				50.f
			);
#endif
		}

	}

	default PrimaryActorTick.bStartWithTickEnabled = false;

//	UFUNCTION(BlueprintOverride)
//	void Tick(float DeltaSeconds)
//	{
//		const float Time = Time::GetGameTimeSeconds();
//		const float Duration = 4.f;
//		const float Alpha = Time % Duration / Duration;
//		const FVector P = Spline.GetLocationAtTime(Alpha, ESplineCoordinateSpace::World, true);
//		System::DrawDebugPoint(P, 30.f, FLinearColor::Yellow);
//	}

	// Will automatically update the 3D spline  
	UFUNCTION(Category = "Helix Properties", CallInEditor)
	void GenerateHelix()
	{
		InitData();
		GenerateHelixData();
		UpdateSpline();
	}

	void InitData()
	{
		TotalIterations = Turns * PointsPerTurn;
		Pitch = Height / Turns;
		StepSize_Angular = 360 / PointsPerTurn;
		StepSize_Angular *= bCounterClockwise ? -1 : 1;
		StepSize_Pitch = Pitch / PointsPerTurn;
		MaxPaddingFromCenter = FMath::Max(Height, Radius);

		Spline.ClearSplinePoints(false);

		CompLocation = Spline.GetLocationAtDistanceAlongSpline(0, ESplineCoordinateSpace::World);
		CompQuat = Spline.GetQuaternionAtSplineInputKey(0, ESplineCoordinateSpace::World);
		CompQuat *= FQuat(FVector::RightVector, PI * 0.5f);
		CompQuat.Normalize();

//		System::DrawDebugLine(CompLocation, CompLocation + CompQuat.Vector() * 1000.f);

		SpiralCenter = CompLocation + CompQuat.Vector()*Height*0.5f;
	}

	void GenerateHelixData()
	{
		const auto AmountOfPoints = PointsPerTurn * Turns;
		SpiralParticleLocations.Reset(AmountOfPoints);

		if (HelixCurvature.GetNumKeys() > 1)
		{
			FVector2D CurvatureLengthRange, CurvatureRadiusRange;
			HelixCurvature.GetValueRange(CurvatureRadiusRange.X, CurvatureRadiusRange.Y);
			HelixCurvature.GetTimeRange(CurvatureLengthRange.X, CurvatureLengthRange.Y);
			const float MaxCurvatureRadius = FMath::Abs(CurvatureRadiusRange.X - CurvatureRadiusRange.Y);
			const float MaxCurvatureLength = FMath::Abs(CurvatureLengthRange.X - CurvatureLengthRange.Y);

			const FVector2D LengthOfHelixRange = FVector2D(0, TotalIterations * StepSize_Angular);

			for (auto i = 0; i < TotalIterations; ++i)
			{
				const float RadStepSize = FMath::DegreesToRadians(i*StepSize_Angular);
				const float CurvatureTime = FMath::GetMappedRangeValueClamped(
					LengthOfHelixRange,
					CurvatureLengthRange,
					i * StepSize_Angular	
				);
				float RadiusScale = HelixCurvature.GetFloatValue(CurvatureTime);

				if(MaxCurvatureRadius != 0.f)
					RadiusScale /= MaxCurvatureRadius;
				else
					RadiusScale /= KINDA_SMALL_NUMBER;

				const FVector Offset = FVector(
					FMath::Sin(RadStepSize) * Radius * RadiusScale,
					FMath::Cos(RadStepSize) * Radius * RadiusScale,
					i*StepSize_Pitch
				);
				const FVector Offset_Rotated = CompQuat.RotateVector(Offset);
				const FVector SpiralPointLocation = CompLocation + Offset_Rotated;
				SpiralParticleLocations.Add(SpiralPointLocation);
			}
		}
		else
		{
			// Just make a straight spline with the desired radius
			for (auto i = 0; i < TotalIterations; ++i)
			{
				const float RadStepSize = FMath::DegreesToRadians(i*StepSize_Angular);
				const FVector Offset = FVector(
					FMath::Sin(RadStepSize) * Radius,
					FMath::Cos(RadStepSize) * Radius,
					i*StepSize_Pitch
				);
				const FVector Offset_Rotated = CompQuat.RotateVector(Offset);
				const FVector SpiralPointLocation = CompLocation + Offset_Rotated;
				SpiralParticleLocations.Add(SpiralPointLocation);
			}
		}

	}

	void UpdateSpline()
	{
		if (SpiralParticleLocations.Num() <= 0)
			return;

		Spline.ClearSplinePoints(false);

		if(bFlipDirection)
		{
			TArray<FVector> NewSpiralLocations;
			NewSpiralLocations.Reserve(SpiralParticleLocations.Num());

			for (int i = SpiralParticleLocations.Num() - 1; i >= 0 ; i--)
				NewSpiralLocations.Add(SpiralParticleLocations[i]);

			SpiralParticleLocations = NewSpiralLocations;
		}

		for (int i = 0; i < SpiralParticleLocations.Num(); ++i)
		{
			Spline.AddSplinePoint(
				SpiralParticleLocations[i],
				ESplineCoordinateSpace::World,
				i == SpiralParticleLocations.Num() - 1
			);
		}

	}

	void DebugPoints()
	{
		System::FlushPersistentDebugLines();
		if (SpiralParticleLocations.Num() > 0)
		{
			for (const FVector PointLocation : SpiralParticleLocations)
			{
				System::DrawDebugPoint(PointLocation, 10.f, FLinearColor::Red, 5.f);
			}
		}
	}

}
































