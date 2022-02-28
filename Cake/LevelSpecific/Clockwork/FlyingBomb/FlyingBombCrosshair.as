
class UFlyingBombCrosshair : UHazeUserWidget
{
	bool bHasAutoAim = false;
	FVector AutoAimLocation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D PixelOffset(0.f, 0.f);

	private bool bLockedOn = true;
	private bool bWasAutoAim = true;

	private FHazeAcceleratedVector2D LerpScreenSpacePosition;
	default LerpScreenSpacePosition.Value = FVector2D(0.5f, 0.5f);

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		FVector2D ScreenSpacePosition;
		bool bAutoAiming = false;
		if (bHasAutoAim)
		{
			if (SceneView::ProjectWorldToViewpointRelativePosition(Player, AutoAimLocation, ScreenSpacePosition)
				&& ScreenSpacePosition.X >= 0.f && ScreenSpacePosition.X <= 1.f
				&& ScreenSpacePosition.Y >= 0.f && ScreenSpacePosition.Y <= 1.f)
			{
				bAutoAiming = true;
			}
			else
			{
				ScreenSpacePosition = FVector2D(0.5f, 0.5f);
			}
		}
		else
		{
			ScreenSpacePosition = FVector2D(0.5f, 0.5f);
		}

		if (bWasAutoAim != bAutoAiming)
		{
			bLockedOn = false;
			bWasAutoAim = bAutoAiming;
		}

		if (bLockedOn)
		{
			LerpScreenSpacePosition.SnapTo(ScreenSpacePosition, FVector2D::ZeroVector);
		}
		else
		{
			LerpScreenSpacePosition.AccelerateTo(ScreenSpacePosition, 0.5f, InDeltaTime);
			if (LerpScreenSpacePosition.Value.Equals(ScreenSpacePosition, 0.01f))
				bLockedOn = true;
		}

		PixelOffset = MyGeometry.LocalSize * LerpScreenSpacePosition.Value;
	}
};