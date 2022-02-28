
enum EMurderMicrophoneSplineType
{
	Qubic,
	Quartic
}

#if EDITOR


class UMurderMicrophoneBodyVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UMurderMicrophoneBodyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        if (!ensure((Component != nullptr) && (Component.Owner != nullptr)))
			return;

		UMurderMicrophoneBodyComponent BodyComp = Cast<UMurderMicrophoneBodyComponent>(Component);

		for(FVector P : BodyComp.SplinePath)
		{
			DrawPoint(P, FLinearColor::Green);
		}
	}
}

#endif // EDITOR

class UMurderMicrophoneBodyComponent : UHazeCableComponent
{
	UPROPERTY()
	EMurderMicrophoneSplineType SplineType = EMurderMicrophoneSplineType::Quartic;

	UPROPERTY()
	float CordDetailLevel = 30.0f;
	private int LastNumPoints = 0;
	float DefaultTileMaterial = 1.0f;
	float DefaultSplineLengthSq = 0.0f;

	default bAttachEnd = false;
	default bAttachStart = false;
	default bSimulatePhysics = false;
	default bGenerateOverlapEvents = false;
	default CollisionProfileName = n"NoCollision";
	default CableWidth = 80.0f;
	default NumSides = 16;
	default TileMaterial = 20.0f;

	UPROPERTY()
	float MaxLength = 5000.0f;

	void UpdateSpline(float DeltaTime)
	{

	}

	UPROPERTY(meta = (MakeEditWidget))
	FVector StartLocation2;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation2;

	UPROPERTY(meta = (MakeEditWidget))
	FVector ControlPoint1;

	UPROPERTY(meta = (MakeEditWidget))
	FVector ControlPoint2;

	UPROPERTY(meta = (MakeEditWidget, EditCondition="SplineType == EMurderMicrophoneSplineType::Quartic", EditConditionHides))
	FVector ControlPoint3;

	TArray<FVector> SplinePath;

	void InitSpline_Qubic()
	{

	}

	UFUNCTION()
	void InitSpline_Quartic()
	{
		const int NumSplinePoints = CalculateNumSplinePointsTotal();

		SplinePath.SetNum(NumSplinePoints);

		// Okay... we are going to make two splines...

		FVector Destination = TransformedStartLocation2;
		FVector Origin = TransformedEndLocation2;
		int NumPoints = CalculateNumSplinePoints_Quartic(Origin, Destination) + 1;
		
		if(!devEnsure(NumPoints < SplinePath.Num(), "Spline point index missmatch"))
			return;


		const FVector Local_ControlPoint1 = TransformedControlPoint1;
		const FVector Local_ControlPoint2 = TransformedControlPoint2;
		const FVector Local_ControlPoint3 = TransformedControlPoint3;

		SplinePath[0] = TransformedStartLocation;
		int Index = 1;
		for(; Index < NumPoints; ++Index)
		{
			float Alpha = FMath::Min(float(Index - 1) / float(NumPoints), 1.0f);
			FVector SplineLoc = Math::GetPointOnQuarticBezierCurveConstantSpeed(Origin, Local_ControlPoint1, Local_ControlPoint2, Local_ControlPoint3, Destination, Alpha);
			SplinePath[Index] = SplineLoc;
		}

		SplinePath[NumPoints] = Destination;
		Index++;
		const FVector CordStartLoc = TransformedStartLocation;

		for(; Index < NumSplinePoints; ++Index)
		{

			SplinePath[Index] = CordStartLoc;
		}

		LastNumPoints = NumPoints;
	}

	private void CalculateSpline_Cubic(float DeltaTime)
	{

	}

	private void CalculateSpline_Quartic(float DeltaTime)
	{
		FVector Destination = TransformedStartLocation2;
		FVector Origin = TransformedEndLocation2;
		//System::DrawDebugSphere(Origin, 100.0f, 12, FLinearColor::Red);
		int NumPoints = CalculateNumSplinePoints_Quartic(Origin, Destination) + 1;
		
		if(!devEnsure(NumPoints < SplinePath.Num(), "Spline point index missmatch"))
			return;

		const float InterpSpeed = 4.0f;
		SplinePath[0] = TransformedStartLocation;
		int Index = 1;
		SplinePath[1] = Origin;
		
		float Alpha = 0.0f;
		float InterpSpeedScalar = 0.0f;
		FVector SplineLoc;

		const FVector Local_ControlPoint1 = TransformedControlPoint1;
		const FVector Local_ControlPoint2 = TransformedControlPoint2;
		const FVector Local_ControlPoint3 = TransformedControlPoint3;
		
		Index = 2;
		for(; Index < NumPoints; ++Index)
		{
			Alpha = FMath::Min(float(Index - 1) / float(NumPoints), 1.0f);
			InterpSpeedScalar = float(NumPoints) / float(Index);
			SplineLoc = Math::GetPointOnQuarticBezierCurveConstantSpeed(Origin, Local_ControlPoint3, Local_ControlPoint2, Local_ControlPoint1, Destination, Alpha);
			SplinePath[Index] = FMath::VInterpTo(SplinePath[Index], SplineLoc, DeltaTime, InterpSpeed * InterpSpeedScalar);
		}

		SplinePath[NumPoints] = Destination;
		Index++;
		const FVector CordStartLoc = TransformedStartLocation;

		// Long loops will kill the system
		for(int Num = SplinePath.Num(); Index < Num; ++Index)
		{
			SplinePath[Index] = FMath::VInterpTo(SplinePath[Index], CordStartLoc, DeltaTime, InterpSpeed);
		}

		LastNumPoints = NumPoints;
	}

	int CalculateNumSplinePointsTotal() const
	{
		return FMath::CeilToInt(MaxLength / CordDetailLevel) + 2;	// +2 because we want an extra location for the head root and one for inside the base.
	}

	float CalculateNumSplinePoints(float SegmentLength) const
	{
		return FMath::CeilToInt(SegmentLength / CordDetailLevel) + 2;	// +2 because final point on head is inside, same for final point inside base.
	}

	float CalculateNumSplinePoints_Quartic(FVector Origin, FVector Destination) const
	{
		const float SegmentLength = Math::CalculateQuarticBezierSegmentLength(Origin, TransformedControlPoint3, TransformedControlPoint2, TransformedControlPoint1, Destination);
		return FMath::CeilToInt(SegmentLength / CordDetailLevel) + 2;	// +2 because final point on head is inside, same for final point inside base.
	}

	FVector GetTransformedStartLocation() const property
	{
		return WorldTransform.TransformPosition(StartLocation);
	}

	FVector GetTransformedStartLocation2() const property
	{
		return WorldTransform.TransformPosition(StartLocation2);
	}

	FVector GetTransformedEndLocation() const property
	{
		return WorldTransform.TransformPosition(EndLocation);
	}

	FVector GetTransformedEndLocation2() const property
	{
		return WorldTransform.TransformPosition(EndLocation2);
	}

	FVector GetTransformedControlPoint1() const property
	{
		return WorldTransform.TransformPosition(ControlPoint1);
	}

	FVector GetTransformedControlPoint2() const property
	{
		return WorldTransform.TransformPosition(ControlPoint2);
	}

	FVector GetTransformedControlPoint3() const property
	{
		return WorldTransform.TransformPosition(ControlPoint3);
	}
}
