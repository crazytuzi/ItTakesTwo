

#if EDITOR

class UConeDetectionDummyComponent : UActorComponent{}

class UConeDetectionComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UConeDetectionComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UConeDetectionComponent Comp = Cast<UConeDetectionComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			return;

		const float Length = Comp.Range;
		const FVector StartLocation = Comp.StartLocation;

		const FVector LocalRightStartLocation = Comp.GetRightStartLocation();
		const FVector LocalLeftStartLocation = Comp.GetLeftStartLocation();
		const FVector LocalUpStartLocation = Comp.GetUpStartLocation();
		const FVector LocalBottomStartLocation = Comp.GetBottomStartLocation();

		const FVector LocalRightOffset = Comp.GetRightOffset();
		const FVector LocalLeftOffset = Comp.GetLeftOffset();
		const FVector LocalUpOffset = Comp.GetUpOffset();
		const FVector LocalBottomOffset = Comp.GetBottomOffset();

		const float ArrowSize = 10.0f;
		const float Thickness = 10;

		DrawArrow(LocalRightStartLocation, LocalRightStartLocation + (LocalRightOffset * Length), FLinearColor::Green, ArrowSize, Thickness);
		DrawArrow(LocalLeftStartLocation, LocalLeftStartLocation + (LocalLeftOffset * Length), FLinearColor::Green, ArrowSize, Thickness);

		DrawArrow(LocalUpStartLocation, LocalUpStartLocation + (LocalUpOffset * Length), FLinearColor::Blue, ArrowSize, Thickness);
		DrawArrow(LocalBottomStartLocation, LocalBottomStartLocation + (LocalBottomOffset * Length), FLinearColor::Blue, ArrowSize, Thickness);
	
		const float NormalLocationLength = Length * 0.5f;
		const float NormalLength = 30.0f;

		const FVector RightNormalStartLocation = LocalRightStartLocation + (LocalRightOffset * NormalLocationLength);
		const FVector LeftNormalStartLocation = LocalLeftStartLocation + (LocalLeftOffset * NormalLocationLength);
		const FVector UpNormalStartLocation = LocalUpStartLocation + (LocalUpOffset * NormalLocationLength);
		const FVector BottomNormalStartLocation = LocalBottomStartLocation + (LocalBottomOffset * NormalLocationLength);

		const float NormalLineThickness = 5;

		DrawArrow(RightNormalStartLocation, RightNormalStartLocation + (Comp.GetRightNormal() * NormalLength), FLinearColor::Red, ArrowSize, NormalLineThickness);
		DrawArrow(LeftNormalStartLocation, LeftNormalStartLocation - (Comp.GetLeftNormal() * NormalLength), FLinearColor::Red, ArrowSize, NormalLineThickness);
		DrawArrow(UpNormalStartLocation, UpNormalStartLocation + (Comp.GetUpNormal() * NormalLength), FLinearColor::Red, ArrowSize, NormalLineThickness);
		DrawArrow(BottomNormalStartLocation, BottomNormalStartLocation - (Comp.GetBottomNormal() * NormalLength), FLinearColor::Red, ArrowSize, NormalLineThickness);

		DrawArrow(Comp.GetStartLocation(), Comp.GetStartLocation() + (Comp.GetForward() * Length), FLinearColor::LucBlue, ArrowSize, NormalLineThickness);
    }
}

#endif // EDITOR

enum EConeDetectionType
{
	Full, // Compare dot from direction placed on line
	//DotOnly,	// Compare dot from forward vector
	None	// No comparison, useful if you only want to check vertical or horizontal.
}

class UConeDetectionComponent : USceneComponent
{
	UPROPERTY(Category = Settings)
	TArray<AActor> CachedIgnoreActors;

	UPROPERTY(Category = Settings)
	float Range = 4000.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0, ClampMax = 180.0))
	float HorizontalAngle = 30.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0, ClampMax = 180.0))
	float VerticalAngle = 60.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0))
	float HorizontalOffset = 10.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0))
	float VerticalOffset = 10.0f;

	UPROPERTY(Category = Settings)
	EConeDetectionType HorizontalDetectionType = EConeDetectionType::Full;

	UPROPERTY(Category = Settings)
	EConeDetectionType VerticalDetectionType = EConeDetectionType::Full;

	UPROPERTY(Category = Settings)
	bool bTraceVisibility = false;

	FVector GetForward() const property { return ForwardVector; }
	FVector GetRight() const property { return RightVector; }
	FVector GetUp() const property { return UpVector; }
	FVector GetStartLocation() const property { return WorldLocation; }

	FVector GetRightOffset() const property
	{
		return GetForward().RotateAngleAxis(HorizontalAngle, GetUp());
	}

	FVector GetLeftOffset() const property
	{
		return GetForward().RotateAngleAxis(-HorizontalAngle, GetUp());
	}

	FVector GetUpOffset() const property
	{
		return GetForward().RotateAngleAxis(VerticalAngle, GetRight());
	}

	FVector GetBottomOffset() const property
	{
		return GetForward().RotateAngleAxis(-VerticalAngle, GetRight());
	}

	FVector GetRightNormal() const property
	{
		return GetRightOffset().CrossProduct(GetUp()).GetSafeNormal();
	}

	FVector GetLeftNormal() const property
	{
		return GetLeftOffset().CrossProduct(GetUp()).GetSafeNormal();
	}

	FVector GetUpNormal() const property
	{
		return GetUpOffset().CrossProduct(GetRight()).GetSafeNormal();
	}

	FVector GetBottomNormal() const property
	{
		return GetBottomOffset().CrossProduct(GetRight()).GetSafeNormal();
	}

	FVector GetRightStartLocation() const property
	{
		return GetStartLocation() + (GetRight() * HorizontalOffset);
	}

	FVector GetLeftStartLocation() const property
	{
		return GetStartLocation() - (GetRight() * HorizontalOffset);
	}

	FVector GetUpStartLocation() const property
	{
		return GetStartLocation() - (GetUp() * VerticalOffset);
	}

	FVector GetBottomStartLocation() const property
	{
		return GetStartLocation() + (GetUp() * VerticalOffset);
	}

	// Pas along owner to the point for trace comparison
	bool IsPointInsideCone(FVector Point, AActor PointOwner = nullptr) const
	{
		const float DistanceSq = WorldLocation.DistSquared(Point);

		if(DistanceSq > FMath::Square(Range))
			return false;

		const bool bInsideVertical = IsPointInsideVerticalAngle(Point, PointOwner);
		const bool bInsideHorizontal = IsPointInsideHorizontalAngle(Point, PointOwner);

		return bInsideVertical && bInsideHorizontal;
	}

	private bool IsPointInsideVerticalAngle(FVector Point, AActor PointOwner) const
	{
		if(VerticalDetectionType == EConeDetectionType::Full)
		{
			const FVector UpDirToTarget = (Point - UpStartLocation).GetSafeNormal();
			const FVector BottomToTarget = (Point - BottomStartLocation).GetSafeNormal();
			const bool bOk = UpDirToTarget.DotProduct(UpNormal) > 0.0f && BottomToTarget.DotProduct(-BottomNormal) > 0.0f;

			if(bOk && bTraceVisibility)
			{
				const bool bTraceOk = TraceVisibility(Point, PointOwner);
				return bTraceOk;
			}

			return bOk;
		}

		return true;
	}

	private bool IsPointInsideHorizontalAngle(FVector Point, AActor PointOwner) const
	{
		if(HorizontalDetectionType == EConeDetectionType::Full)
		{
			const FVector RightDirToTarget = (Point - RightStartLocation).GetSafeNormal();
			const FVector LeftDirToTarget = (Point - LeftStartLocation).GetSafeNormal();
			const bool bOk = RightDirToTarget.DotProduct(RightNormal) > 0.0f && LeftDirToTarget.DotProduct(-LeftNormal) > 0.0f;

			if(bOk && bTraceVisibility)
			{
				const bool bTraceOk = TraceVisibility(Point, PointOwner);
				return bTraceOk;
			}

			return bOk;
		}

		return true;
	}

	private bool TraceVisibility(FVector Point, AActor PointOwner) const
	{
		FHitResult Hit;
		System::LineTraceSingle(WorldLocation, Point, ETraceTypeQuery::Visibility, false, CachedIgnoreActors, EDrawDebugTrace::None, Hit, false);
		return !Hit.bBlockingHit || (PointOwner != nullptr && Hit.bBlockingHit && Hit.Actor == PointOwner);
	}
}
