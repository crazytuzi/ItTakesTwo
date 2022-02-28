class UWorldSpaceCircleWidget : UHazeUserWidget
{
	// Location of the surface
	UPROPERTY(NotEditable)
	FVector AimLocation;

	// Quaternion describing the surface to project onto
	UPROPERTY(NotEditable)
	FQuat SurfaceQuat = FQuat::Identity;

	float CircleAngle = 0.f;

	// Color of the circle
	UPROPERTY(Category = "Circle")
	FLinearColor LineColor = FLinearColor::White;

	// Radius of the circle
	UPROPERTY(Category = "Circle")
	float CircleRadius = 80.f;

	// Number of line segments making up the circle
	UPROPERTY(Category = "Circle")
	int NumLines = 6;

	// Number of individual straight lines each segment is made of
	UPROPERTY(Category = "Circle")
	int LineResolution = 5;

	// Modifies both shape and its shadow
	UPROPERTY(Category = "Circle")
	float LineThicknessMultiplier = 1.f;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		CircleAngle += DeltaTime * 1.2f;
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		// The angle in-between each line
		//	(*2 since we want to have a space in-between each line)
		float LineStep = TAU / (NumLines * 2);

		// The angle in-between each segment
		float SegmentStep = LineStep / LineResolution;

		// Base transform of the circle
		FTransform AimTransform;
		AimTransform.Location = AimLocation;
		AimTransform.Rotation = SurfaceQuat * FQuat(FVector::ForwardVector, CircleAngle);

		// Draw each line..
		for(int i=0; i<NumLines; ++i)
		{
			// Draw shadows (black, thicker line)
			for(int j=0; j<LineResolution; j++)
			{
				float FromAngle = LineStep * (i * 2) + SegmentStep * j;
				float ToAngle = LineStep * (i * 2) + SegmentStep * (j + 1);

				// Get the world-space positions of this segment (offset from base-transform)
				FTransform FromTransform = FTransform::Identity;
				FromTransform.Location = FVector(0.f, FMath::Sin(FromAngle), FMath::Cos(FromAngle)) * CircleRadius;
				FTransform ToTransform = FTransform::Identity;
				ToTransform.Location = FVector(0.f, FMath::Sin(ToAngle), FMath::Cos(ToAngle)) * CircleRadius;

				FromTransform = FromTransform * AimTransform;
				ToTransform = ToTransform * AimTransform;

				// Get their position in pixel-space
				FVector2D FromPixel = WorldToPixel(FromTransform.Location);
				FVector2D ToPixel = WorldToPixel(ToTransform.Location);

				WidgetBlueprint::DrawLine(Context, FromPixel, ToPixel, FLinearColor(0.f, 0.f, 0.f, 0.4f * LineColor.A), true, 5.2f * LineThicknessMultiplier);
			}

			// Draw actual line
			for(int j=0; j<LineResolution; j++)
			{
				float FromAngle = LineStep * (i * 2) + SegmentStep * j;
				float ToAngle = LineStep * (i * 2) + SegmentStep * (j + 1);

				// Get the world-space positions of this segment (offset from base-transform)
				FTransform FromTransform = FTransform::Identity;
				FromTransform.Location = FVector(0.f, FMath::Sin(FromAngle), FMath::Cos(FromAngle)) * CircleRadius;
				FTransform ToTransform = FTransform::Identity;
				ToTransform.Location = FVector(0.f, FMath::Sin(ToAngle), FMath::Cos(ToAngle)) * CircleRadius;

				FromTransform = FromTransform * AimTransform;
				ToTransform = ToTransform * AimTransform;

				// Get their position in pixel-space
				FVector2D FromPixel = WorldToPixel(FromTransform.Location);
				FVector2D ToPixel = WorldToPixel(ToTransform.Location);

				WidgetBlueprint::DrawLine(Context, FromPixel, ToPixel, LineColor, true, 3.5f * LineThicknessMultiplier);
			}
		}
	}

	FVector2D WorldToPixel(FVector WorldLoc) const
	{
		AHazePlayerCharacter DeprojectPlayer = Player;
		AHazePlayerCharacter FullscreenPlayer = SceneView::GetFullScreenPlayer();
		if (FullscreenPlayer != nullptr && FullscreenPlayer != Player)
			DeprojectPlayer = FullscreenPlayer;

		FVector2D Screen;
		SceneView::ProjectWorldToViewpointRelativePosition(DeprojectPlayer, WorldLoc, Screen);

		FGeometry Geometry = GetCachedGeometry();
		return Screen * Geometry.GetLocalSize();
	}
}