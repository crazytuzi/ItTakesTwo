import Peanuts.Crosshair.SurfaceProjectedCircleWidget;

struct FScreenSpaceTransform
{
	FVector AxisX;
	FVector AxisY;
	FVector Translation;

	FScreenSpaceTransform(
		float X1, float X2, float X3,
		float Y1, float Y2, float Y3,
		float T1, float T2, float T3)
	{
		AxisX = FVector(X1, X2, X3);
		AxisY = FVector(Y1, Y2, Y3);
		Translation = FVector(T1, T2, T3);
	}
	FScreenSpaceTransform(FVector InAxisX, FVector InAxisY, FVector InTranslation)
	{
		AxisX = InAxisX;
		AxisY = InAxisY;
		Translation = InTranslation;
	}
	FScreenSpaceTransform(FVector2D InAxisX, FVector2D InAxisY, FVector2D InTranslation)
	{
		AxisX = FVector(InAxisX.X, InAxisX.Y, 0.f);
		AxisY = FVector(InAxisY.X, InAxisY.Y, 0.f);
		Translation = FVector(InTranslation.X, InTranslation.Y, 1.f);
	}
	FScreenSpaceTransform(float RotationAngle, FVector2D InTranslation)
	{
		float SinAngle = 0.f, CosAngle = 0.f;
		FMath::SinCos(SinAngle, CosAngle, RotationAngle);

		AxisX = FVector(CosAngle, -SinAngle, 0.f);
		AxisY = FVector(SinAngle, CosAngle, 0.f);
		Translation = FVector(InTranslation.X, InTranslation.Y, 1.f);
	}

	FVector2D TransformVector(FVector2D Vec) const
	{
		FVector Result = (this * FVector(Vec.X, Vec.Y, 0.f));
		return FVector2D(Result.X, Result.Y);
	}
	FVector2D TransformPosition(FVector2D Vec) const
	{
		FVector Result = (this * FVector(Vec.X, Vec.Y, 1.f));
		return FVector2D(Result.X, Result.Y);
	}

	FVector Row(int Index) const
	{
		switch(Index)
		{
			case 0: return AxisX;
			case 1: return AxisY;
			case 2: return Translation;
			default: ensure(false);
		}

		return FVector();
	}
	FVector Col(int Index) const
	{
		if (!ensure(Index < 3))
			return FVector();

		return FVector(AxisX[Index], AxisY[Index], Translation[Index]);
	}

	float Dot(FVector A, FVector B) const { return A.DotProduct(B); }

	FScreenSpaceTransform opMul(FScreenSpaceTransform Other) const
	{
		FScreenSpaceTransform Result;
		Result = FScreenSpaceTransform(
			Dot(Col(0), Other.Row(0)), Dot(Col(1), Other.Row(0)), Dot(Col(2), Other.Row(0)),
			Dot(Col(0), Other.Row(1)), Dot(Col(1), Other.Row(1)), Dot(Col(2), Other.Row(1)),
			Dot(Col(0), Other.Row(2)), Dot(Col(1), Other.Row(2)), Dot(Col(2), Other.Row(2))
		);

		return Result;
	}
	FVector opMul(FVector Vec) const
	{
		return
			AxisX * Vec.X +
			AxisY * Vec.Y +
			Translation * Vec.Z;
	}
}

class USapWeaponCrosshairWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	float PressurePercent = 1.f;

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

	// Number of individual straight lines each segment is made of
	UPROPERTY(Category = "Circle")
	int CircleResolution = 20;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		CircleAngle += DeltaTime * PressurePercent * 1.6f;
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		FScreenSpaceTransform ScreenTransform = WorldToScreenSpaceTransform(AimLocation, SurfaceQuat);
		FScreenSpaceTransform RotationTransform = FScreenSpaceTransform(CircleAngle, FVector2D::ZeroVector);
		ScreenTransform = ScreenTransform * RotationTransform;

		// Draw the pressure circle
		DrawPressureCircle(Context, ScreenTransform, CircleRadius * PressurePercent);

		// Draw the line-circle
		float LineTheta = TAU / (NumLines * 2.f);
		for(int i=0; i<NumLines; ++i)
		{
			float Angle = LineTheta * (i * 2);
			DrawCircleLineSegment(Context, ScreenTransform, CircleRadius, Angle, LineTheta);
		}
	}

	void DrawCircleLineSegment(FPaintContext& Context, FScreenSpaceTransform Transform, float CircleRadius, float LineAngle, float LineTheta) const
	{
		TArray<FVector2D> Vertices;
		Vertices.SetNum(LineResolution);

		float AngleStep = LineTheta / LineResolution;

		for(int i=0; i<LineResolution; ++i)
		{
			float Angle = LineAngle + AngleStep * i;
			FVector2D Vert = FVector2D(FMath::Cos(Angle), FMath::Sin(Angle)) * CircleRadius;
			Vertices[i] = Transform.TransformPosition(Vert);
		}

		// Background
		WidgetBlueprint::DrawLines(Context, Vertices, FLinearColor::Black, true, 4.7f);
		// Foreround
		WidgetBlueprint::DrawLines(Context, Vertices, FLinearColor::White, true, 3.5f);
	}

	void DrawPressureCircle(FPaintContext& Context, FScreenSpaceTransform Transform, float Radius) const
	{
		TArray<FVector2D> CircleVerts;
		CircleVerts.SetNum(CircleResolution);

		for(int i=0; i<CircleResolution; ++i)
		{
			float Angle = (TAU / (CircleResolution - 1)) * i;

			FVector2D Vert = FVector2D(FMath::Cos(Angle), FMath::Sin(Angle)) * Radius;
			CircleVerts[i] = Transform.TransformPosition(Vert);
		}

		WidgetBlueprint::DrawCustomShape(Context, CircleVerts, FLinearColor(1.f, 1.f, 1.f, 0.4f));
	}

	FScreenSpaceTransform WorldToScreenSpaceTransform(FVector WorldLocation, FQuat WorldRotation) const
	{
		// Deproject center, X, and Y axis
		FVector2D Center = WorldToPixel(WorldLocation);
		FVector2D AxisX = WorldToPixel(WorldLocation + WorldRotation.ForwardVector) - Center;
		FVector2D AxisY = WorldToPixel(WorldLocation + WorldRotation.RightVector) - Center;

		return FScreenSpaceTransform(AxisX, AxisY, Center);
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