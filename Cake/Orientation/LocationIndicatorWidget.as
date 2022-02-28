class ULocationIndicatorWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	UWidget GetIndicator() const
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(const FGeometry& Geometry, float DeltaTime)
	{
		UWidget IndicatorWidget = GetIndicator();
		if (IndicatorWidget == nullptr)
			return;

		FVector2D ViewRes = SceneView::GetPlayerViewResolution(Player);

		//IndicatorWidget.SetRenderScale(FVector2D(0.03f, 0.05f));

		// FVector WorldPos = Player.OtherPlayer.ActorTransform.TransformPosition(FVector(0,0,250));

		// FVector2D IndicatorPos = FVector2D::ZeroVector;
		// FVector2D Fraction;
		// SceneView::ProjectWorldToViewpointRelativePosition(Player, WorldPos, Fraction);
		
		// FVector2D PixelPos; 
		// FVector2D ViewportPos;
		// SlateBlueprint::LocalToViewport(Geometry, Fraction, PixelPos, ViewportPos);

		// IndicatorPos = (Fraction - FVector2D(0.5f, 0.5f)) * ViewRes;
		// PrintToScreen("Frac: " + Fraction + " Pos: " + IndicatorPos + " Res: " + ViewRes + " ViewportPos: " + ViewportPos + " PixelPos: " + PixelPos);

		// IndicatorPos = -ViewRes * 0.5f;
		//IndicatorWidget.SetRenderTranslation(IndicatorPos);

		
		if ((ViewRes.X < 0.1f) || (ViewRes.Y < 0.1f))
			ViewRes = SceneView::GetPlayerViewResolution(Player.OtherPlayer);

		FVector2D IndicatorPos = FVector2D::ZeroVector;
		FVector2D PixelPos; 
		FVector2D ViewportPos;
		float Buffer = 0.1f;
		SlateBlueprint::LocalToViewport(Geometry, Geometry.GetLocalSize() * 0.5f, PixelPos, ViewportPos);

		if (PixelPos.X < ViewRes.X * Buffer)
			IndicatorPos.X += 2 * (ViewRes.X * Buffer - PixelPos.X);
		if (PixelPos.X > ViewRes.X * (1.f - Buffer))
			IndicatorPos.X += 2 * ((ViewRes.X * (1.f - Buffer) - PixelPos.X));
		
		if (PixelPos.Y < ViewRes.Y * Buffer)
			IndicatorPos.Y += 2 * (ViewRes.Y * Buffer - PixelPos.Y);
		if (PixelPos.Y > ViewRes.Y * (1.f - Buffer))
			IndicatorPos.Y += 2 * ((ViewRes.Y * (1.f - Buffer) - PixelPos.Y));

		IndicatorWidget.SetRenderTranslation(IndicatorPos);
		//Print("Res: " + ViewRes + " Pos: " + ViewportPos + " Indicator: " + IndicatorPos + " Pixel: " + PixelPos);
	}
}