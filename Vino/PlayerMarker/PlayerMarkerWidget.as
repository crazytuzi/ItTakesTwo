class UPlayerMarkerWidget : UHazeUserWidget
{
	UPROPERTY()
	bool bIsMay = true;

	UPROPERTY()
	bool bForceShow = false;

	UPROPERTY()
	UImage MarkerImageRef = nullptr;

	UPROPERTY()
	bool bIsOffScreen = false;

	UPROPERTY()
	float ShowDistance = 6000.f;

	UPROPERTY()
	float ShowFadeDistance = 200.f;

	// Screen space offset at minimum distance
	UPROPERTY()
	float MinDistScreenSpaceOffset = 20.f;

	// Screen space offset at maximum distance
	UPROPERTY()
	float MaxDistScreenSpaceOffset = 20.f;

	// Distance at which the maximum screen space offset is reached
	UPROPERTY()
	float MaxOffsetDist = 10000.f;

	float OffscreenLerp = -1.f;
	float DistanceHideLerp = -1.f;

	float PrevOffset = 0.f;
	float PrevHeadingAngle = 0.f;
	float PrevScreenSpaceOffset = 0.f;

	USceneComponent OtherIndicatorComp;

	UFUNCTION(BlueprintOverride)
	void OnAttachToEdgeOfScreen()
	{
		bIsOffScreen = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDetachFromEdgeOfScreen()
	{
		bIsOffScreen = false;
	}

	UFUNCTION()
	void Setup(AHazePlayerCharacter InPlayer)
	{
		if (InPlayer.IsMay())
			bIsMay = true;
		else
			bIsMay = false;

		BP_Setup();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Setup() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		float Distance; 
		if (OtherIndicatorComp != nullptr)
			Distance = Player.ActorLocation.Distance(OtherIndicatorComp.WorldLocation);
		else
			Distance = Player.ActorLocation.Distance(Player.OtherPlayer.ActorLocation);
		float PrevDistanceLerp = DistanceHideLerp;
		float PrevOffscreenLerp = OffscreenLerp;

		if (bForceShow)
			DistanceHideLerp = 1.f;
		else
			DistanceHideLerp = Math::Saturate((Distance - ShowDistance) / ShowFadeDistance);

		if (bIsOffScreen)
			OffscreenLerp = Math::Saturate(OffscreenLerp + (DeltaTime * 3.f));
		else
			OffscreenLerp = Math::Saturate(OffscreenLerp - (DeltaTime * 3.f));

		if (PrevDistanceLerp != DistanceHideLerp || PrevOffscreenLerp != OffscreenLerp)
		{
			float HeadingAngle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.f).HeadingAngle();
			PrevHeadingAngle = HeadingAngle;
			MarkerImageRef.SetOpacity(FMath::Max(DistanceHideLerp, OffscreenLerp));
			MarkerImageRef.SetRenderTransformAngle(
				Math::LerpAngle(
					90.f,
					FMath::RadiansToDegrees(HeadingAngle),
					OffscreenLerp)
			);
		}
		else if (OffscreenLerp > 0.f)
		{
			float HeadingAngle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.f).HeadingAngle();
			if (PrevHeadingAngle != HeadingAngle)
			{
				PrevHeadingAngle = HeadingAngle;
				MarkerImageRef.SetRenderTransformAngle(
					Math::LerpAngle(
						90.f,
						FMath::RadiansToDegrees(HeadingAngle),
						OffscreenLerp)
				);
			}
		}

		float NewOffset = Player.OtherPlayer.CapsuleComponent.GetUnscaledCapsuleHalfHeight() * 2.f;
		if (NewOffset != PrevOffset)
		{
			SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, NewOffset));
			PrevOffset = NewOffset;
		}

		float NewScreenSpaceOffset = 
			FMath::Lerp(
				FMath::Lerp(MinDistScreenSpaceOffset, MaxDistScreenSpaceOffset, Math::Saturate(Distance / MaxOffsetDist)),
				0.f,
				OffscreenLerp
			);
		if (NewScreenSpaceOffset != PrevScreenSpaceOffset)
		{
			MarkerImageRef.SetRenderTranslation(FVector2D(0.f, -NewScreenSpaceOffset));
			PrevScreenSpaceOffset = NewScreenSpaceOffset;
		}
	}
}