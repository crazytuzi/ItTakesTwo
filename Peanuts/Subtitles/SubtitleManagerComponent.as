const FConsoleVariable CVar_SubtitlesEnabled("Haze.SubtitlesEnabled", 2);
const FConsoleVariable CVar_CaptionsEnabled("Haze.ClosedCaptionsEnabled", 0);
const FConsoleVariable CVar_CodyGameplaySubtitles("Haze.CodyGameplaySubtitles", 1);
const FConsoleVariable CVar_MayGameplaySubtitles("Haze.MayGameplaySubtitles", 1);
const FConsoleVariable CVar_SubtitleBackground("Haze.SubtitleBackground", 0);

struct FActiveSubtitle
{
	FHazeSubtitleLine Line;
	float RemainingDuration;
	UObject Instigator;
	UHazeSubtitleAsset FromAsset;
	EHazeSubtitlePriority Priority;
};

class USubtitleWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeSubtitleLine ActiveLine;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EHazeSubtitlePriority ActivePriority;

	UPROPERTY(NotEditable)
	UWidget MainPositionWidget;

	USubtitleManagerComponent SubtitleComp;

	UPROPERTY()
	bool bSubtitleBackground = false;

	UPROPERTY()
	bool bFullscreenSubtitles = false;

	void Show()
	{
	}

	UFUNCTION(BlueprintPure)
	bool ShouldBeItalic()
	{
		// Never italicize in fullscreen
		if (SceneView::IsFullScreen())
			return false;

		// Italicize text that the other player said
		if (Player != nullptr)
		{
			if (Player.IsCody())
			{
				if (ActiveLine.SourceTag == n"MayBark")
					return true;
			}
			else
			{
				if (ActiveLine.SourceTag == n"CodyBark")
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateActiveLine() {}

	// Filter the given subtitle to display the correct subtitles based on game settings.
	UFUNCTION(BlueprintPure)
	FText FilterSubtitleText(FText Subtitle)
	{
		if (Subtitle.IsEmpty())
			return Subtitle;

		TArray<FString> Lines;
		Subtitle.ToString().ParseIntoArray(Lines, "\n", false);

		FString OutStr;
		bool bIsCC = false;
		bool bIsNoCC = false;

		for (FString& Line : Lines)
		{
			FString StartTrimmedLine = Line.TrimStart();
			if (StartTrimmedLine.StartsWith("CC:"))
			{
				bIsCC = true;
				bIsNoCC = false;
				Line = StartTrimmedLine.RightChop(3).TrimStart();
			}
			else if (StartTrimmedLine.StartsWith("NO_CC:"))
			{
				bIsCC = false;
				bIsNoCC = true;
				Line = StartTrimmedLine.RightChop(6).TrimStart();
			}

			if (CVar_CaptionsEnabled.GetInt() == 1)
			{
				if (bIsNoCC)
					continue;
			}
			else
			{
				if (bIsCC)
					continue;
			}

			if (OutStr.Len() != 0)
				OutStr += "\n";
			OutStr += Line;
		}

		return FText::FromString(OutStr);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTIme)
	{
		bool bForceUpdate = false;
		bool bHaveSubtitle = false;
		FText PrevText = ActiveLine.Text;
		if (SubtitleComp.GetShownSubtitle(ActiveLine, ActivePriority))
			bHaveSubtitle = true;

		// Update the position of the main widget to follow the player's view rect
		if (MainPositionWidget != nullptr)
		{
			FVector2D GeomSize = Geom.LocalSize;
			UCanvasPanelSlot MainSlot = Cast<UCanvasPanelSlot>(MainPositionWidget.Slot);

			bool bForcedFullScreen = false;

			// Menu subtitles are always fullscreen
			if (Player == nullptr)
				bForcedFullScreen = true;

			// If both players are in a splitscreen cutscene, the subtitles should be fullscreen
			if (!ActiveLine.Text.IsEmpty() && ActivePriority == EHazeSubtitlePriority::Cutscene)
			{
				if (Player != nullptr && Player.bIsControlledByCutscene && Player.OtherPlayer.bIsControlledByCutscene
				&& Player.ActiveLevelSequenceActor == Player.OtherPlayer.ActiveLevelSequenceActor)
				{
					bForcedFullScreen = true;
				}
			}

			if (bForcedFullScreen)
			{
				MainSlot.SetPosition(FVector2D(0.f, 0.f));
				MainSlot.SetSize(GeomSize);
				MainPositionWidget.SetVisibility(ESlateVisibility::HitTestInvisible);

				if (!bFullscreenSubtitles)
				{
					bFullscreenSubtitles = true;
					bForceUpdate = true;
				}
			}
			else
			{
				FVector2D MinPos;
				FVector2D MaxPos;
				SceneView::GetUnletterboxedPercentageScreenRectFor(Player, MinPos, MaxPos);

				MainSlot.SetPosition(FVector2D(MinPos.X * GeomSize.X, MinPos.Y * GeomSize.Y));
				MainSlot.SetSize(FVector2D((MaxPos.X - MinPos.X) * GeomSize.X, (MaxPos.Y - MinPos.Y) * GeomSize.Y));

				if (MaxPos.X - MinPos.X < 0.25f)
					MainPositionWidget.SetVisibility(ESlateVisibility::Hidden);
				else if (MaxPos.Y - MinPos.Y < 0.25f)
					MainPositionWidget.SetVisibility(ESlateVisibility::Hidden);
				else
					MainPositionWidget.SetVisibility(ESlateVisibility::HitTestInvisible);

				bool bIsFullscreen = SceneView::IsFullScreen();
				if (bIsFullscreen != bFullscreenSubtitles)
				{
					bFullscreenSubtitles = bIsFullscreen;
					bForceUpdate = true;
				}
			}
		}

		// Update whether to show subtitle background
		bool bShowBackground = CVar_SubtitleBackground.GetInt() != 0;
		if (bShowBackground != bSubtitleBackground)
		{
			bSubtitleBackground = bShowBackground;
			bForceUpdate = true;
		}

		// Update the line of text that is shown
		if (bHaveSubtitle)
		{
			if (!PrevText.IdenticalTo(ActiveLine.Text) || bForceUpdate)
				BP_UpdateActiveLine();
		}
		else if (!PrevText.IsEmpty())
		{
			ActiveLine = FHazeSubtitleLine();
			BP_UpdateActiveLine();
		}
	}
};

class USubtitleManagerComponent : UHazeSubtitleComponentBase
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	TSubclassOf<USubtitleWidget> SubtitleWidget;

	private TArray<FActiveSubtitle> ActiveSubtitles;
	private bool bSubtitlesActive = false;
	private USubtitleWidget Widget;
	private float LastSubtitleShownTime = 0.f;
	private AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (Widget != nullptr)
			Widget::RemoveFullscreenWidget(Widget);
	}

	UFUNCTION(BlueprintOverride)
	void ShowSubtitle(const FHazeSubtitleLine& Line, float Duration = 0.f, UObject Instigator = nullptr, EHazeSubtitlePriority Priority = EHazeSubtitlePriority::Medium)
	{
		FActiveSubtitle Subtitle;
		Subtitle.Line = Line;
		Subtitle.RemainingDuration = Duration;
		Subtitle.Instigator = Instigator;
		Subtitle.Priority = Priority;

		ActiveSubtitles.Add(Subtitle);

		ActivateSubtitles();
		LastSubtitleShownTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void ShowSubtitlesFromAsset(UHazeSubtitleAsset Asset, float TimeInAsset, UObject Instigator = nullptr, EHazeSubtitlePriority Priority = EHazeSubtitlePriority::Cutscene)
	{
		// Remove any lines that were already added by this asset
		for (int i = ActiveSubtitles.Num() - 1; i >= 0; --i)
		{
			if (ActiveSubtitles[i].FromAsset == Asset)
				ActiveSubtitles.RemoveAtSwap(i);
		}

		// Add lines that match the current specified time
		for (const FHazeSubtitleTiming& Timing : Asset.Lines)
		{
			if (Timing.StartTime > TimeInAsset)
				continue;
			if (Timing.EndTime <= TimeInAsset)
				continue;

			FActiveSubtitle Subtitle;
			Subtitle.Line = Timing.Line;
			Subtitle.RemainingDuration = 0.f;
			Subtitle.Instigator = Instigator;
			Subtitle.FromAsset = Asset;
			Subtitle.Priority = Priority;

			ActiveSubtitles.Add(Subtitle);
		}

		if (ActiveSubtitles.Num() != 0)
			ActivateSubtitles();
		LastSubtitleShownTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void ClearSubtitlesByInstigator(UObject Instigator)
	{
		for (int i = ActiveSubtitles.Num() - 1; i >= 0; --i)
		{
			if (ActiveSubtitles[i].Instigator == Instigator)
				ActiveSubtitles.RemoveAtSwap(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ClearSubtitlesByAsset(UHazeSubtitleAsset Asset)
	{
		for (int i = ActiveSubtitles.Num() - 1; i >= 0; --i)
		{
			if (ActiveSubtitles[i].FromAsset == Asset)
				ActiveSubtitles.RemoveAtSwap(i);
		}
	}

	bool GetShownSubtitle(FHazeSubtitleLine& OutSubtitleLine, EHazeSubtitlePriority& OutPriority)
	{
		if (CVar_SubtitlesEnabled.GetInt() == 0)
			return false;

		int ActivePriority = -1;
		bool bHasSubtitle = false;

		for (int i = ActiveSubtitles.Num() - 1; i >= 0; --i)
		{
			int Priority = int(ActiveSubtitles[i].Priority);
			if (Priority > ActivePriority)
			{
				// Skip non-cutscene subtitles if we're set to that mode
				if (Priority < int(EHazeSubtitlePriority::Cutscene))
				{
					if (PlayerOwner != nullptr && PlayerOwner.IsCody())
					{
						if (CVar_CodyGameplaySubtitles.GetInt() == 0)
							continue;
					}

					if (PlayerOwner != nullptr && PlayerOwner.IsMay())
					{
						if (CVar_MayGameplaySubtitles.GetInt() == 0)
							continue;
					}
				}

				ActivePriority = Priority;
				OutSubtitleLine = ActiveSubtitles[i].Line;
				OutPriority = ActiveSubtitles[i].Priority;
				bHasSubtitle = true;
			}
		}

		return bHasSubtitle;
	}

	private void ActivateSubtitles()
	{
		if (bSubtitlesActive)
			return;
		bSubtitlesActive = true;
		SetComponentTickEnabled(true);

		if (Widget == nullptr)
		{
			Widget = Cast<USubtitleWidget>(Widget::AddFullscreenWidget(SubtitleWidget, EHazeWidgetLayer::Overlay));
			if (PlayerOwner != nullptr)
				Widget.OverrideWidgetPlayer(PlayerOwner);
		}
		else
		{
			Widget::AddExistingFullscreenWidget(Widget, EHazeWidgetLayer::Overlay);
		}

		Widget.SetWidgetPersistent(true);
		Widget.SubtitleComp = this;
		Widget.Show();
		Widget.ActiveLine = FHazeSubtitleLine();
		Widget.BP_UpdateActiveLine();
	}

	private void DeactivateSubtitles()
	{
		if (!bSubtitlesActive)
			return;
		bSubtitlesActive = false;
		SetComponentTickEnabled(false);

		if (Widget != nullptr)
			Widget::RemoveFullscreenWidget(Widget);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Update remaining time on any added subtitles
		for (int i = ActiveSubtitles.Num() - 1; i >= 0; --i)
		{
			if (ActiveSubtitles[i].RemainingDuration > 0.f)
			{
				ActiveSubtitles[i].RemainingDuration -= DeltaTime;
				if (ActiveSubtitles[i].RemainingDuration <= 0.f)
					ActiveSubtitles.RemoveAtSwap(i);
			}
		}

		if (ActiveSubtitles.Num() == 0)
		{
			if (Time::GetGameTimeSince(LastSubtitleShownTime) > 2.f)
				DeactivateSubtitles();
		}
		else
		{
			LastSubtitleShownTime = Time::GetGameTimeSeconds();
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		ActiveSubtitles.Reset();
	}
};
