enum EContextIconState
{
	Hidden,
	Dot,
	Disabled,
	Visible,
	Highlighted,
	ProgressCircleFocus,
	ShowInputIcon,
	DisabledWithProgress,
};

enum EContextIconProgressStyle
{
	Hidden,
	Proximity,
	Progress,
};

UCLASS(Abstract)
class UContextIconWidget : UHazeUserWidget
{
	UPROPERTY()
	FSlateBrush Image;

	EContextIconProgressStyle RadialProgressStyle = EContextIconProgressStyle::Hidden;

	UPROPERTY(NotEditable)
	EContextIconState IconState = EContextIconState::Hidden;
	UPROPERTY()
	float EdgeAttachDot = 0.f;

	UPROPERTY(NotEditable)
	float HighlightedLerpAlpha = 0.f;
	UPROPERTY(NotEditable)
	float ProgressCircleFocusLerpAlpha = 0.f;
	UPROPERTY(NotEditable)
	float IsAttachedLerpAlpha = 0.f;
	UPROPERTY(NotEditable)
	float DistanceDotLerpAlpha = 0.f;
	UPROPERTY(NotEditable)
	float ContextIconLerpAlpha = 0.f;
	UPROPERTY(NotEditable)
	float RadialProgressLerpAlpha = 0.f;
	UPROPERTY(NotEditable)
	float InputButtonLerpAlpha = 0.f;
	UPROPERTY(NotEditable)
	float ShadowLerpAlpha = 0.f;

	bool bIsAttachedToEdge = false;
	float LerpSpeed = 5.f;

	UFUNCTION()
	void UpdateRadialProgressStyle(EContextIconProgressStyle Style)
	{
		RadialProgressStyle = Style;
	}

	UFUNCTION()
	void UpdateIconState(EContextIconState NewIconState)
	{
		if (NewIconState == IconState)
			return;
		IconState = NewIconState;
		UpdateAllLerpValues();
	}

	UFUNCTION()
	void SetAttachedToEdge(bool Attached)
	{
		bIsAttachedToEdge = Attached;
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateAttachedLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateDistanceDotLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateContextIconLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateProgressCircleFocusLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateHighlightedLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateShadowLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateRadialProgressLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateInputButtonLerpAlpha(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateIconState(EContextIconState NewState)
	{
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UpdateAllLerpValues();
	}

	void UpdateAllLerpValues()
	{
		BP_UpdateIconState(IconState);
		BP_UpdateHighlightedLerpAlpha(HighlightedLerpAlpha);
		BP_UpdateProgressCircleFocusLerpAlpha(ProgressCircleFocusLerpAlpha);
		BP_UpdateAttachedLerpAlpha(IsAttachedLerpAlpha);
		BP_UpdateDistanceDotLerpAlpha(DistanceDotLerpAlpha);
		BP_UpdateContextIconLerpAlpha(ContextIconLerpAlpha);
		BP_UpdateRadialProgressLerpAlpha(RadialProgressLerpAlpha);
		BP_UpdateInputButtonLerpAlpha(InputButtonLerpAlpha);
		BP_UpdateShadowLerpAlpha(ShadowLerpAlpha);
	}

	/* This function will reset the current values and call the all the internal functions
	 * This function is very important to call if the the icons are in a container, else the values will fail
	*/
	UFUNCTION()
	void Setup()
	{
		IconState = EContextIconState::Hidden;
		HighlightedLerpAlpha = 0;
		ProgressCircleFocusLerpAlpha = 0;
		IsAttachedLerpAlpha = 0.f;
		DistanceDotLerpAlpha = 0;
		ContextIconLerpAlpha = 0;
		RadialProgressLerpAlpha = 0;
		InputButtonLerpAlpha = 0;
		ShadowLerpAlpha = 0;

		UpdateAllLerpValues();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		// Update lerp alpha factors for widget
		if (IconState == EContextIconState::Highlighted)
		{
			if (HighlightedLerpAlpha < 1.f)
			{
				HighlightedLerpAlpha = Math::Saturate(HighlightedLerpAlpha + Timer * LerpSpeed);
				BP_UpdateHighlightedLerpAlpha(HighlightedLerpAlpha);
			}
		}
		else
		{
			if (HighlightedLerpAlpha > 0.f)
			{
				HighlightedLerpAlpha = Math::Saturate(HighlightedLerpAlpha - Timer * LerpSpeed);
				BP_UpdateHighlightedLerpAlpha(HighlightedLerpAlpha);
			}
		}

		if (IconState == EContextIconState::ProgressCircleFocus)
		{
			if (ProgressCircleFocusLerpAlpha < 1.f)
			{
				ProgressCircleFocusLerpAlpha = Math::Saturate(ProgressCircleFocusLerpAlpha + Timer * LerpSpeed);
				BP_UpdateProgressCircleFocusLerpAlpha(ProgressCircleFocusLerpAlpha);
			}
		}
		else
		{
			if (ProgressCircleFocusLerpAlpha > 0.f)
			{
				ProgressCircleFocusLerpAlpha = Math::Saturate(ProgressCircleFocusLerpAlpha - Timer * LerpSpeed);
				BP_UpdateProgressCircleFocusLerpAlpha(ProgressCircleFocusLerpAlpha);
			}
		}

		if (bIsAttachedToEdge)
		{
			if (IsAttachedLerpAlpha < 1.f)
			{
				IsAttachedLerpAlpha = Math::Saturate(IsAttachedLerpAlpha + Timer * LerpSpeed);
				BP_UpdateAttachedLerpAlpha(IsAttachedLerpAlpha);
			}
		}
		else
		{
			if (IsAttachedLerpAlpha > 0.f)
			{
				IsAttachedLerpAlpha = Math::Saturate(IsAttachedLerpAlpha - Timer * LerpSpeed);
				BP_UpdateAttachedLerpAlpha(IsAttachedLerpAlpha);
			}
		}

		if (IconState == EContextIconState::Dot)
		{
			if (DistanceDotLerpAlpha < 1.f)
			{
				DistanceDotLerpAlpha = Math::Saturate(DistanceDotLerpAlpha + Timer * LerpSpeed);
				BP_UpdateDistanceDotLerpAlpha(DistanceDotLerpAlpha);
			}
		}
		else
		{
			if (DistanceDotLerpAlpha > 0.f)
			{
				DistanceDotLerpAlpha = Math::Saturate(DistanceDotLerpAlpha - Timer * LerpSpeed);
				BP_UpdateDistanceDotLerpAlpha(DistanceDotLerpAlpha);
			}
		}

		if (IconState == EContextIconState::Disabled
			|| IconState == EContextIconState::Visible
			|| IconState == EContextIconState::Dot
			|| IconState == EContextIconState::Highlighted
			|| IconState == EContextIconState::ProgressCircleFocus
			|| IconState == EContextIconState::DisabledWithProgress)
		{
			if (ContextIconLerpAlpha < 1.f)
			{
				ContextIconLerpAlpha = Math::Saturate(ContextIconLerpAlpha + Timer * LerpSpeed);
				BP_UpdateContextIconLerpAlpha(ContextIconLerpAlpha);
			}
		}
		else
		{
			if (ContextIconLerpAlpha > 0.f)
			{
				ContextIconLerpAlpha = Math::Saturate(ContextIconLerpAlpha - Timer * LerpSpeed);
				BP_UpdateContextIconLerpAlpha(ContextIconLerpAlpha);
			}
		}

		if (IconState == EContextIconState::Visible
			|| IconState == EContextIconState::ProgressCircleFocus
			|| (IconState == EContextIconState::Highlighted && RadialProgressStyle == EContextIconProgressStyle::Progress)
			|| IconState == EContextIconState::DisabledWithProgress)
		{
			if (RadialProgressLerpAlpha < 1.f)
			{
				RadialProgressLerpAlpha = Math::Saturate(RadialProgressLerpAlpha + Timer * LerpSpeed);
				BP_UpdateRadialProgressLerpAlpha(RadialProgressLerpAlpha);
			}
		}
		else
		{
			if (RadialProgressLerpAlpha > 0.f)
			{
				RadialProgressLerpAlpha = Math::Saturate(RadialProgressLerpAlpha - Timer * LerpSpeed);
				BP_UpdateRadialProgressLerpAlpha(RadialProgressLerpAlpha);
			}
		}

		if (IconState == EContextIconState::ShowInputIcon)
		{
			if (InputButtonLerpAlpha < 1.f)
			{
				InputButtonLerpAlpha = Math::Saturate(InputButtonLerpAlpha + Timer * LerpSpeed);
				BP_UpdateInputButtonLerpAlpha(InputButtonLerpAlpha);
			}
		}
		else
		{
			if (InputButtonLerpAlpha > 0.f)
			{
				InputButtonLerpAlpha = Math::Saturate(InputButtonLerpAlpha - Timer * LerpSpeed);
				BP_UpdateInputButtonLerpAlpha(InputButtonLerpAlpha);
			}
		}

		if (IconState != EContextIconState::Hidden)
		{
			if (ShadowLerpAlpha < 1.f)
			{
				ShadowLerpAlpha = Math::Saturate(ShadowLerpAlpha + Timer * LerpSpeed);
				BP_UpdateShadowLerpAlpha(ShadowLerpAlpha);
			}
		}
		else
		{
			if (ShadowLerpAlpha > 0.f)
			{
				ShadowLerpAlpha = Math::Saturate(ShadowLerpAlpha - Timer * LerpSpeed);
				BP_UpdateShadowLerpAlpha(ShadowLerpAlpha);
			}
		}
	}

	UFUNCTION()
	void SetOpacityFromProgress(UWidget Widget, float InProgress, UWidget ImageContainer, float TargetProgress, float FarAwayContainerOpacity = 0.6f)
	{
		float UseProgress = FMath::Lerp(0.25f, 0.5f,
			1.f - FMath::Square((1.f - Math::Saturate(InProgress))));

		float MinOpacity = 0.f;
		if (RadialProgressStyle == EContextIconProgressStyle::Progress)
			MinOpacity = 0.5f;

		Widget.SetRenderOpacity(
			FMath::Lerp(MinOpacity, 1.f, UseProgress * Math::Saturate(EdgeAttachDot))
		);
		
		float ContainerOpacity = 1.f;
		if (RadialProgressStyle == EContextIconProgressStyle::Proximity)
		{
			if (TargetProgress < 1.f)
				ContainerOpacity = FarAwayContainerOpacity;
		}

		ImageContainer.SetRenderOpacity(ContainerOpacity);
	}

}

UCLASS(Abstract)
class UContextIconContainerWidget : UHazeActivationPointWidget
{
	UContextIconWidget ContextIcon;

	UFUNCTION()
	void SetupContextIcon(UContextIconWidget Widget)
	{
		ContextIcon = Widget;
	}
}

UCLASS(Abstract)
class UContextIconWidget_Old : UHazeUserWidget
{
	UPROPERTY()
	FSlateBrush Image;
}