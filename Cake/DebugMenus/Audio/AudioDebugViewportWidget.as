import Vino.Characters.PlayerCharacter;

class UAudioDebugViewportWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	UHazeTextWigdet GetHeader() property 
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UVerticalBox GetVerticalBox() property 
	{
		return nullptr;
	}

	bool bIsMay = false;
	EHazeSplitScreenMode LastSplitScreenMode;

	void Setup(bool IsMay)
	{
		bIsMay = IsMay;

		AddToViewport();
		UpdatePositioning(true);
	}

	void UpdatePositioning(bool bForce = false) 
	{
		auto SplitScreenMode = SceneView::GetSplitScreenMode();
		bool bModeChanged = SplitScreenMode != LastSplitScreenMode;
		LastSplitScreenMode = SplitScreenMode;

		if (!bModeChanged && !bForce)
			return;

		FVector2D ViewportSize;
		if (SplitScreenMode == EHazeSplitScreenMode::Horizontal)
		{
			ViewportSize.X = 0;
			ViewportSize.Y = bIsMay ? 0 : 0.5f;
		}else {
			ViewportSize.X = bIsMay ? 0 : 0.5f;
			ViewportSize.Y = 0;
		}
		SetDesiredSizeInViewport(ViewportSize);

		FAnchors Anchors;
		if (SplitScreenMode == EHazeSplitScreenMode::Horizontal)
		{
			Anchors.Minimum.Y = bIsMay ? 0 : 0.5f;
			Anchors.Maximum.Y = bIsMay ? 0.5f : 1.f;

			Anchors.Minimum.X = bIsMay ? 0 : 0;
			Anchors.Maximum.X = bIsMay ? 1.f : 1.f;
		}else {
			Anchors.Minimum.Y = bIsMay ? 0 : 0;
			Anchors.Maximum.Y = bIsMay ? 1.f : 1.f;

			Anchors.Minimum.X = bIsMay ? 0 : 0.5f;
			Anchors.Maximum.X = bIsMay ? 0.5f : 1.f;
		}
		SetAnchorsInViewport(Anchors);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float InDeltaTime)
	{
		UpdatePositioning();
	}

	void AddChild(UWidget Widget)
	{
		VerticalBox.AddChild(Widget);
	}

	void RemoveChild(UWidget Widget)
	{
		VerticalBox.RemoveChild(Widget);
	}
}