import Cake.LevelSpecific.SnowGlobe.Snowfolk.ProjectedHeightSplineActor;

class UConnectedSplineFollowerComponent : UActorComponent
{
	UPROPERTY()
	AProjectedHeightSplineActor SplineActor;

	UProjectedHeightSplineComponent Spline;

	UPROPERTY()
	float Offset = 0.f;

	UPROPERTY()
	float DistanceOnSpline = 0.f;

	UPROPERTY()
	float Height = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.ProjectedHeightSplineComponent;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	}

	UFUNCTION()
	void AddOffset(float OffsetToAdd)
	{
		Offset += OffsetToAdd;

		Update();
	}

	UFUNCTION()
	void AddDistance(float DistanceToAdd)
	{
		DistanceOnSpline += DistanceToAdd;

		Update();
	}

	UFUNCTION()
	void AddHeight(float HeightToAdd)
	{
		Height += HeightToAdd;

		Update();
	}


	void Update()
	{
		if (SplineActor == nullptr)
			return;

		if (DistanceOnSpline > SplineActor.ProjectedHeightSplineComponent.SplineLength)
		{		
			DistanceOnSpline -= SplineActor.ProjectedHeightSplineComponent.SplineLength;
			SplineActor = SplineActor.GetNextSplineActor(Offset, true);
		}
		else if (DistanceOnSpline < 0)
		{			
			SplineActor = SplineActor.GetNextSplineActor(Offset, false);	
			
			if (SplineActor == nullptr)
				return;
			
			DistanceOnSpline +=	SplineActor.ProjectedHeightSplineComponent.SplineLength;
		}

		FTransform PointTransform = SplineActor.ProjectedHeightSplineComponent.GetTransformAtDistanceAlongSpline(DistanceOnSpline, ESplineCoordinateSpace::World, true);

		float SplineWidth = PointTransform.Scale3D.Y * SplineActor.ProjectedHeightSplineComponent.BaseWidth;

		Offset = FMath::Clamp(Offset, -SplineWidth, SplineWidth);

		// - 0.001f to prevent offset to be 1.0 and sample next row
		float NormalizedOffset = FMath::Clamp(Offset / SplineWidth, -1.f, 1.f - 0.001f);

		float ZOffset = SplineActor.ProjectedHeightSplineComponent.GetZAtDistanceAndOffset(DistanceOnSpline, NormalizedOffset);

		Height = FMath::Clamp(Height, ZOffset, 10000.f);

		FTransform TranformAtDistance = SplineActor.ProjectedHeightSplineComponent.GetTransformAtDistanceAlongSpline(DistanceOnSpline, ESplineCoordinateSpace::World, true);
		FVector Location = TranformAtDistance.Location + TranformAtDistance.Rotation.RightVector * Offset;

	//	Owner.SetActorLocationAndRotation(Location, TranformAtDistance.Rotation);
	}

	FTransform GetSplineTransform(bool bUseOffset = false)
	{
		if (SplineActor == nullptr)
			return FTransform::Identity;

		FTransform PointTransform = SplineActor.ProjectedHeightSplineComponent.GetTransformAtDistanceAlongSpline(DistanceOnSpline, ESplineCoordinateSpace::World, true);
		
		if (bUseOffset)
			PointTransform.Location = PointTransform.Location + PointTransform.Rotation.RightVector * Offset;

		return PointTransform;
	}

	void GetNormalAndLocationFromFootPrint(float &OutZ, FVector &OutNormal, FVector &OutLocation, float Radius = 100.f, int Samples = 4, float ExtraDistanceOffset = 0.f)
	{
		float AverageZ = 0.f;
		FVector AverageNormal;
		FVector AverageLocation;

		TArray<FVector> LocationSamples;
		TArray<FVector> NormalSamples;
		float AngleStep = TAU / Samples;

		for (int i = 0; i < Samples; i++)
		{
			AProjectedHeightSplineActor SampleSplineActor = SplineActor;
			float SampleDistance = DistanceOnSpline + FMath::Cos(i * AngleStep) * Radius;
			SampleDistance += ExtraDistanceOffset;
			float SampleOffset = Offset + FMath::Sin(i * AngleStep) * Radius;

			// Get Samples From Next/Previous Spline if needed
			if (SampleDistance > SampleSplineActor.ProjectedHeightSplineComponent.SplineLength)
			{		
				SampleDistance -= SampleSplineActor.ProjectedHeightSplineComponent.SplineLength;
				SampleSplineActor = SampleSplineActor.GetNextSplineActor(SampleOffset, true);
			}
			else if (SampleDistance < 0)
			{			
				SampleSplineActor = SampleSplineActor.GetNextSplineActor(SampleOffset, false);	
				
				// Should be avoided...
				if (SampleSplineActor == nullptr)
					continue;
				SampleDistance += SampleSplineActor.ProjectedHeightSplineComponent.SplineLength;
			}

			FTransform SampleTransform = SampleSplineActor.ProjectedHeightSplineComponent.GetTransformAtDistanceAlongSpline(SampleDistance, ESplineCoordinateSpace::World, true);

			float SplineWidth = SampleTransform.Scale3D.Y * SampleSplineActor.ProjectedHeightSplineComponent.BaseWidth;

			// - 0.001f to prevent offset to be 1.0 and sample next row
			float NormalizedOffset = FMath::Clamp(SampleOffset / SplineWidth, -1.f, 1.f - 0.001f);

			float ZOffset = SampleSplineActor.ProjectedHeightSplineComponent.GetZAtDistanceAndOffset(SampleDistance, NormalizedOffset);
			AverageZ += ZOffset;

			FVector SampleWorldLocation = SampleTransform.Location + (FVector::UpVector * ZOffset) + (SampleTransform.Rotation.RightVector * SampleOffset);
			AverageLocation += SampleWorldLocation;

			LocationSamples.Add(SampleWorldLocation);
		//	System::DrawDebugSphere(SampleWorldLocation, 25.f, 12, FLinearColor::Green, 0, 20.f);
		//	System::DrawDebugPoint(SampleWorldLocation, 50.f, FLinearColor::Yellow, 0.f);
		}

		for (int i = 0; i < LocationSamples.Num(); i++)
		{					
			FVector SampleNormal = (LocationSamples[Math::IWrap(i + 1, 0, LocationSamples.Num() - 1)] - LocationSamples[i]).CrossProduct((LocationSamples[Math::IWrap(i + 2, 0, LocationSamples.Num() - 1)] - LocationSamples[i]));
			AverageNormal += SampleNormal;
		}

		OutZ = (AverageZ / LocationSamples.Num());
		OutNormal = (AverageNormal / LocationSamples.Num()).GetSafeNormal();
		OutLocation = AverageLocation / LocationSamples.Num();

	//	System::DrawDebugLine(OutLocation, OutLocation + OutNormal * 1000.f, FLinearColor::Blue, 0.f, 20.f);
	}

}