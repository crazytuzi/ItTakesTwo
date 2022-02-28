
class URythmWidget : UHazeUserWidget
{
	UPROPERTY()
	float MovementSpeed = 350.0f;

	UPROPERTY()
	float CollisionRange = 120.0f;

	UPROPERTY()
	bool bDebugDraw = false;

	FLinearColor DebugDrawColor = FLinearColor::Green;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		if(PanelSlot == nullptr)
		{
			return;
		}

		FVector2D Position = PanelSlot.Position;
		Position.Y += (MovementSpeed * DeltaTime);
		PanelSlot.SetPosition(Position);
	}

	bool IsOverlapping(URythmWidget OtherRythmWidget) const
	{
		FVector2D OtherPosition = OtherRythmWidget.PanelSlot.Position;
		const float OtherRange = OtherRythmWidget.CollisionRange * 0.5f;

		const float OtherTop = OtherPosition.Y - OtherRange;
		const float OtherBottom = OtherPosition.Y + OtherRange;

		FVector2D MyPosition = PanelSlot.Position;

		const float MyTop = MyPosition.Y - (CollisionRange * 0.5f);
		const float MyBottom = MyPosition.Y + (CollisionRange * 0.5f);

		if(MyBottom > OtherTop && MyTop < OtherBottom)
		{
			return true;
		}

		return false;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		if(PanelSlot == nullptr || !bDebugDraw)
		{
			return;
		}

		const FVector2D Size = PanelSlot.GetSize();

		const float StartY = Size.Y * 0.5f;

		const float Length = CollisionRange * 0.5f;
		FVector2D AY(Size.X * 0.5f, StartY + Length);
		FVector2D BY(Size.X * 0.5f, StartY - Length);

		FVector2D AX1(0.0f, StartY + Length);
		FVector2D BX1(Size.X, StartY + Length);

		FVector2D AX2(0.0f, StartY - Length);
		FVector2D BX2(Size.X, StartY - Length);

		WidgetBlueprint::DrawLine(Context, AY, BY, DebugDrawColor, false, 2.0f);
		WidgetBlueprint::DrawLine(Context, AX1, BX1, DebugDrawColor, false, 2.0f);
		WidgetBlueprint::DrawLine(Context, AX2, BX2, DebugDrawColor, false, 2.0f);
	}
#endif // EDITOR

	UCanvasPanelSlot GetPanelSlot() const property
	{
		return Cast<UCanvasPanelSlot>(Slot);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Hit Success"))
	void BP_OnHitSucess(){}

	// When the rythm goes out of bounds
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Failure"))
	void BP_OnFailure(){}
}