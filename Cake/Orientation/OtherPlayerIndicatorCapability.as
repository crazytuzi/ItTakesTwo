import Cake.Orientation.OtherPlayerIndicatorWidget;
import Effects.PostProcess.PostProcessing;

class UOtherPlayerIndicatorCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	// Widget Properties
	UPROPERTY()
	TSubclassOf<UOtherPlayerIndicatorWidget> WidgetClass;
	UOtherPlayerIndicatorWidget Widget;
	UPostProcessingComponent PostProcessingComponent;
	bool bUsePostProcessComponent = false;

	AHazePlayerCharacter OwningPlayer;

	// The actual location of the indicator on the screen
	FVector2D IndicatorPosition;

	/* The location of the indicator, projected to the edge of the screen
		Used to calculate the fade out of the indicator	*/
	FVector2D IndicatorEdgePosition;

	// How far the indicator is padded from the edge of the screen.
	FVector2D Padding = FVector2D(100.f, 100.f);


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		PostProcessingComponent = UPostProcessingComponent::Get(OwningPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{			
		if (SceneView::IsFullScreen())
			return EHazeNetworkActivation::DontActivate;
		
		if (!WidgetClass.IsValid())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SceneView::IsFullScreen())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Widget = Cast<UOtherPlayerIndicatorWidget>(OwningPlayer.AddWidget(WidgetClass));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		OwningPlayer.RemoveWidget(Widget);
		Widget = nullptr;
	}	

	FVector2D GetPlayerViewResolution() property
	{
		return SceneView::GetPlayerViewResolution(OwningPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

		// Get the resolution and padded resolution of the viewport
		FVector2D PlayerViewResolutionPadded = PlayerViewResolution - Padding;
		
		// Get the screen percentage location of the other player
		FVector OtherWorldLocation = OwningPlayer.OtherPlayer.CapsuleComponent.WorldLocation;
		FVector2D OtherScreenPercentage;
		SceneView::ProjectWorldToViewpointRelativePosition(OwningPlayer, OtherWorldLocation, OtherScreenPercentage);

		// Convert percentage to screen position
		FVector2D OtherScreenPosition = OtherScreenPercentage * PlayerViewResolution;
		// Convert screen position to center screen for future calculations
		FVector2D OtherCenteredScreenPosition = OtherScreenPosition - PlayerViewResolution * 0.5f;

		// Calculate slope, used for finding the edge of screen intersection for the indicator
		float Slope;
		if (OtherCenteredScreenPosition.X != 0)
			Slope = OtherCenteredScreenPosition.Y / OtherCenteredScreenPosition.X;

		if (Slope == 0)
			return;

		/* 		Calculate the positions of the indicator, and the edge of screen position		*/
		// Check vertical
		if (OtherCenteredScreenPosition.Y < 0)
		{
			// Top of screen
			IndicatorPosition.X = (-PlayerViewResolutionPadded.Y / 2) / Slope;
			IndicatorPosition.Y = -PlayerViewResolutionPadded.Y / 2;

			IndicatorEdgePosition.X = (-PlayerViewResolution.Y / 2) / Slope;
			IndicatorEdgePosition.Y = -PlayerViewResolution.Y / 2;
		}
		else
		{
			IndicatorPosition.X = (PlayerViewResolutionPadded.Y / 2) / Slope;
			IndicatorPosition.Y = (PlayerViewResolutionPadded.Y / 2);

			IndicatorEdgePosition.X = (PlayerViewResolution.Y / 2) / Slope;
			IndicatorEdgePosition.Y = (PlayerViewResolution.Y / 2);
		}

		// Check horizontal
		if (IndicatorPosition.X < -PlayerViewResolutionPadded.X / 2)
		{
			IndicatorPosition.X = -PlayerViewResolutionPadded.X / 2;
			IndicatorPosition.Y = Slope * -PlayerViewResolutionPadded.X / 2;

			IndicatorEdgePosition.X = -PlayerViewResolution.X / 2;
			IndicatorEdgePosition.Y = Slope * -PlayerViewResolution.X / 2;
		}
		else if (IndicatorPosition.X > PlayerViewResolutionPadded.X / 2)
		{
			IndicatorPosition.X = PlayerViewResolutionPadded.X / 2;
			IndicatorPosition.Y = Slope * PlayerViewResolutionPadded.X / 2;

			IndicatorEdgePosition.X = PlayerViewResolution.X / 2;
			IndicatorEdgePosition.Y = Slope * PlayerViewResolution.X / 2;
		}

		// Convert centered screen position to screen position for the widget;
		FVector2D UnCenteredIndicatorPosition = IndicatorPosition + PlayerViewResolution * 0.5f;

		Widget.AnchorPos = UnCenteredIndicatorPosition / PlayerViewResolution;
		Widget.bOtherPlayerOnScreen = IsOtherPlayerOnScreen();
		Widget.bTargetIsMay = OwningPlayer.OtherPlayer.IsMay();
		Widget.IndicatorRotationAngle = FMath::RadiansToDegrees(FMath::Atan2(OtherCenteredScreenPosition.Y, OtherCenteredScreenPosition.X));
		Widget.IndicatorOpacity = GetIndicatorOpacity(OtherCenteredScreenPosition);	

		if (bUsePostProcessComponent)
		{
			PostProcessingComponent.PlayerIndicatorSize = 0.01f;
			PostProcessingComponent.PlayerIndicatorActive = 0.5f;
			PostProcessingComponent.PlayerIndicatorAngle = 	FMath::RadiansToDegrees(FMath::Atan2(OtherCenteredScreenPosition.Y, OtherCenteredScreenPosition.X));
		}
	}

	bool ShouldShowIndicator()
	{
		if (!IsOtherPlayerOnScreen())
			return false;
		else
			return true;
	}

	bool IsOtherPlayerOnScreen()
	{	
		// Get the screen percentage location of the other player
		FVector OtherWorldLocation = OwningPlayer.OtherPlayer.CapsuleComponent.WorldLocation;
		FVector2D OtherScreenPercentage;
		SceneView::ProjectWorldToViewpointRelativePosition(OwningPlayer, OtherWorldLocation, OtherScreenPercentage);

		// Convert percentage to screen position
		FVector2D OtherScreenPosition = OtherScreenPercentage * PlayerViewResolution;

		return IsScreenPositionOnScreen(OtherScreenPosition);
	}

	bool IsScreenPositionOnScreen(FVector2D ScreenPosition)
	{
		if (ScreenPosition.Y > 0 + (Padding.Y * 0.5f) && ScreenPosition.Y < PlayerViewResolution.Y - (Padding.Y * 0.5f)
			&& ScreenPosition.X < PlayerViewResolution.X - (Padding.X * 0.5f) && ScreenPosition.X > 0 + (Padding.X * 0.5f))
			return true;
		else
			return false;
	}

	float GetIndicatorOpacity(FVector2D OtherCenteredScreenPosition)
	{
		if (Padding.Size() == 0)
			return 1.f;

		FVector2D TargetToIndicator = (IndicatorPosition - OtherCenteredScreenPosition);
		FVector2D EdgeToIndicator = (IndicatorPosition - IndicatorEdgePosition);

		float Opacity;

		// Divide by 0 check
		if (EdgeToIndicator.Size() != 0)
			Opacity = FMath::Clamp(TargetToIndicator.Size() / EdgeToIndicator.Size(), 0.f, 1.0f) * FMath::Sign(EdgeToIndicator.DotProduct(TargetToIndicator));
		else
			Opacity = 0.f;

		return Opacity;

		/*
		-- Starts fading in when the target is off screen. Unintended, but actually could be nice
		FVector2D FromIndicator = (IndicatorEdgePosition - IndicatorPosition);
		FVector2D FromTarget = (IndicatorEdgePosition - OtherCenteredScreenPosition);
		float Opacity = FMath::Clamp(FromTarget.Size() / FromIndicator.Size(), 0.f, 1.f) * FMath::Sign(FromIndicator.DotProduct(FromTarget)) * -1;
		*/
	}
}