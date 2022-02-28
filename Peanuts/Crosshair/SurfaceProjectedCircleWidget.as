import Peanuts.Crosshair.WorldSpaceCircleWidget;

class USurfaceProjectedCircleWidget : UWorldSpaceCircleWidget
{
	int NumSpreadNodes = 10;
	TArray<FVector2D> SurfaceSpreadOffsets;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// Create spread trace offsets
		SurfaceSpreadOffsets.Add(FVector2D(0.f, 0.f));
		float AngleStep = TAU / NumSpreadNodes;

		for(int i=0; i<NumSpreadNodes; ++i)
		{
			float Angle = AngleStep * i;
			SurfaceSpreadOffsets.Add(
				FVector2D(FMath::Cos(Angle), FMath::Sin(Angle)) * FMath::RandRange(20.f, 80.f)
			);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		UpdateSurfaceQuat(DeltaTime);
		Super::Tick(Geom, DeltaTime);
	}

	void UpdateSurfaceQuat(float DeltaTime)
	{
		// Calculate the orientation of the surface (since we're rotating the reticle around it)
		// We want the rotation if the circle to be fairly stable even though you look around a lot
		// So we have to find one vector thats fairly consistent as a compliment to the normal

		// The cameras up-vector works pretty well! As the only time that will be parallel with the
		// normal is when we're looking parallel to a flat surface, in which we won't really see the circle anyways
		AHazePlayerCharacter ScreenPlayer = SceneView::IsFullScreen() ? SceneView::GetFullScreenPlayer() : Player;
		if (!devEnsure(ScreenPlayer != nullptr, "ScreenPlayer is null for SurfaceProjectedCircleWidget, did you add it as a fullscreen widget? That is not allowed!"))
			return;

		FVector AimOrigin = ScreenPlayer.ViewLocation;
		FVector NormalPerpen = ScreenPlayer.ViewRotation.UpVector + ScreenPlayer.ViewRotation.ForwardVector * 0.3f;

		FVector SpreadNormal = GetSurfaceSpreadNormal(ScreenPlayer, AimLocation, AimOrigin);
		SpreadNormal = SpreadNormal.ConstrainToPlane(ScreenPlayer.ViewRotation.GetRightVector()).GetSafeNormal();
		FVector Temp = SpreadNormal.CrossProduct(NormalPerpen);
		NormalPerpen = SpreadNormal.CrossProduct(Temp).GetSafeNormal();

		FQuat TargetSurfaceQuat = Math::MakeQuatFromXZ(SpreadNormal, NormalPerpen);
		SurfaceQuat = FQuat::Slerp(SurfaceQuat, TargetSurfaceQuat, DeltaTime * 12.f);
	}

	FVector GetSurfaceSpreadNormal(AHazePlayerCharacter ScreenPlayer, FVector WorldLocation, FVector AimOrigin) const
	{
		FVector Up = ScreenPlayer.ViewRotation.UpVector;
		FVector Right = ScreenPlayer.ViewRotation.RightVector;

		int NumHits = 0;
		FVector NormalTotal = FVector::ZeroVector;

		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Player);

		for(int i=0; i<SurfaceSpreadOffsets.Num(); ++i)
		{
			FVector Location =
				WorldLocation +
				Right * SurfaceSpreadOffsets[i].X +
				Up * SurfaceSpreadOffsets[i].Y;

			Location += (Location - AimOrigin).GetSafeNormal() * 100.f;
			FHitResult Hit;
			System::LineTraceSingle(
				AimOrigin, Location,
				ETraceTypeQuery::SapTrace, false, IgnoreActors,
				EDrawDebugTrace::None, Hit, true);

			if (Hit.bBlockingHit && Hit.Time > 0.8f)
			{
				NumHits++;
				NormalTotal += Hit.Normal;
			}
		}

		if (NumHits == 0)
		{
			return -ScreenPlayer.ViewRotation.ForwardVector;
		}

		return NormalTotal.GetSafeNormal();
	}
}