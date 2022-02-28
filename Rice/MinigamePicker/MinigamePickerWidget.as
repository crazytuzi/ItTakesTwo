
event void FOnMinigameSelected(FHazeProgressPointRef Minigame);

import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

class UMinigamePickerRow : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeChapter MinigameChapter;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeChapter WithinGameChapter;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeChapterGroup WithinGameChapterGroup;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsUnlocked = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHasReachedChapter = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsSelected = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsHovered = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bClickable = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int MayWins = 0;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	int CodyWins = 0;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	int Draws = 0;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	int MayScore = 0;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	int CodyScore = 0;

	UMinigamePickerWidget Picker;

	private bool bHasTickedForSound = false;
	private int InternalMouseOverCount = 0;

	UFUNCTION(BlueprintPure)
	EHazeSelectPlayer GetLeader()
	{
		if (MinigameChapter.MinigameScoreType == EHazeChapterMinigameScoreType::RoundsWon)
		{
			if (MayWins > CodyWins)
				return EHazeSelectPlayer::May;
			else if (CodyWins > MayWins)
				return EHazeSelectPlayer::Cody;
			else
				return EHazeSelectPlayer::None;
		}
		else
		{
			if (MayScore > CodyScore)
				return EHazeSelectPlayer::May;
			else if (CodyScore > MayScore)
				return EHazeSelectPlayer::Cody;
			else
				return EHazeSelectPlayer::None;
		}
	}

	UFUNCTION(BlueprintPure)
	int GetLeaderScore()
	{
		if (MinigameChapter.MinigameScoreType == EHazeChapterMinigameScoreType::RoundsWon)
			return FMath::Max(MayWins, CodyWins);
		else
			return FMath::Max(MayScore, CodyScore);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Initialize() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UpdateVisibility();
		bHasTickedForSound = true;
	}

	void UpdateVisibility()
	{
		if (bIsSelected || bHasReachedChapter)
			SetVisibility(ESlateVisibility::Visible);
		else
			SetVisibility(ESlateVisibility::Collapsed);
	}

	void Select()
	{
		Picker.SelectMinigame(MinigameChapter.ProgressPoint, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry Geom, FPointerEvent MouseEvent)
	{
		if (bClickable)
		{
			bIsHovered = true;
			
			if (bIsUnlocked)
				Game::NarrateText(MinigameChapter.Name);
		}

		if(bHasTickedForSound && !bIsSelected)
		{				

			const bool bIsPaused = Game::IsPausedForAnyReason();

			if(!bIsPaused)
			{
				const float NormalizedInstanceCount = FMath::Clamp(GetAudioManager().MenuWidgetMouseHoverSoundCount / 5.f, 0.f, 1.f);
				UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Menu_ButtonHover_TriggerRate", NormalizedInstanceCount);
			}

			GetAudioManager().UI_OnSelectionChanged_Hover_Background_Mouse();

			if(InternalMouseOverCount == 0 && !bIsPaused)
			{
				GetAudioManager().MenuWidgetMouseHoverSoundCount ++;
				InternalMouseOverCount ++;
				System::SetTimer(this, n"ResetMouseOverRTPC", 0.25f, false);
			}			
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bIsHovered = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{			
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{
			if (bIsHovered && bIsUnlocked && bClickable)
				Select();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void ResetMouseOverRTPC()
	{
		GetAudioManager().MenuWidgetMouseHoverSoundCount --;
		InternalMouseOverCount --;
	}

};

class UMinigamePickerWidget : UHazeUserWidget
{
	UPROPERTY(NotEditable)
	UScrollBox ContainerList;

	UPROPERTY()
	TSubclassOf<UMinigamePickerRow> RowWidgetType;

	UPROPERTY()
	FOnMinigameSelected OnMinigameSelected;

	UPROPERTY()
	bool bIsLobby = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int TotalMinigameCount = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int UnlockedMinigameCount = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int TotalMayWins = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int TotalCodyWins = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int TotalDraws = 0;

	bool bHasUnlockedMinigames = true;
	bool bHasVisibleMinigames = true;
	bool bHasTickedForSound = false;

	private TArray<UMinigamePickerRow> Rows;
	private UHazeChapterDatabase ChapterDB;
	private int SelectedIndex = -1;

	UFUNCTION()
	void Initialize()
	{
		ChapterDB = UHazeChapterDatabase::GetChapterDatabase();
		bHasUnlockedMinigames = false;

		SelectedIndex = -1;
		for (auto Row : Rows)
			Row.RemoveFromParent();
		Rows.Empty();

		TotalMayWins = 0;
		TotalCodyWins = 0;
		TotalDraws = 0;

		TotalMinigameCount = 0;
		UnlockedMinigameCount = 0;

		FHazeChapter GameChapter;
		FHazeChapterGroup GameChapterGroup;
		for (int i = 0, Count = ChapterDB.ChapterCount; i < Count; ++i)
		{
			FHazeChapter Chapter = ChapterDB.GetChapterByIndex(i);
			if (!Chapter.bIsMinigame)
			{
				GameChapter = Chapter;
				GameChapterGroup = ChapterDB.GetChapterGroup(Chapter);
				continue;
			}

			auto Row = Cast<UMinigamePickerRow>(Widget::CreateWidget(this, RowWidgetType.Get()));
			Row.MinigameChapter = Chapter;
			Row.WithinGameChapter = GameChapter;
			Row.WithinGameChapterGroup = GameChapterGroup;
			Row.bHasReachedChapter = Save::IsChapterSelectUnlocked(Chapter.ProgressPoint);
			Row.bIsUnlocked = Row.bHasReachedChapter && Save::IsMinigameUnlocked(Chapter.MinigameId);
			Row.bIsSelected = false;
			Row.bClickable = CanControlSelection();
			Row.Picker = this;

			Row.MayScore = Save::GetPersistentProfileCounter(FName(Row.MinigameChapter.MinigameId+"_MayHighScore"), Type = EHazeSaveDataType::MinigameLocal);
			Row.CodyScore = Save::GetPersistentProfileCounter(FName(Row.MinigameChapter.MinigameId+"_CodyHighScore"), Type = EHazeSaveDataType::MinigameLocal);

			Row.MayWins = Save::GetPersistentProfileCounter(FName(Row.MinigameChapter.MinigameId+"_MayWinsData"), Type = EHazeSaveDataType::MinigameLocal);
			Row.CodyWins = Save::GetPersistentProfileCounter(FName(Row.MinigameChapter.MinigameId+"_CodyWinsData"), Type = EHazeSaveDataType::MinigameLocal);
			Row.Draws = Save::GetPersistentProfileCounter(FName(Row.MinigameChapter.MinigameId+"_DrawData"), Type = EHazeSaveDataType::MinigameLocal);

			TotalMayWins += Row.MayWins;
			TotalCodyWins += Row.CodyWins;
			TotalDraws += Row.Draws;

			TotalMinigameCount += 1;

			if (Row.bIsUnlocked)
			{
				UnlockedMinigameCount += 1;
				bHasUnlockedMinigames = true;
				if (SelectedIndex == -1)
				{
					Row.bIsSelected = true;
					SelectedIndex = Rows.Num();
				}
			}

			if (Row.bHasReachedChapter)
			{
				bHasVisibleMinigames = true;
			}

			Row.BP_Initialize();
			Row.UpdateVisibility();
			ContainerList.AddChild(Row);
			Rows.Add(Row);
		}

		bHasTickedForSound = false;
		BP_InitializeGlobalStats();
		UpdateSelectedMinigame();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		bHasTickedForSound = true;
	}

	void UpdateSelectedMinigame()
	{
		auto Row = GetSelectedRow();
		if (Row != nullptr)
		{
			BP_OnSelectedMinigameChanged(Row);
			BP_ClearScore();

			switch (Row.MinigameChapter.MinigameScoreType)
			{
				case EHazeChapterMinigameScoreType::RoundsWon:
					BP_SetRoundsWon(Row.MayWins, Row.CodyWins);
				break;
				case EHazeChapterMinigameScoreType::HighestScore:
					BP_SetHighScore(Row.MayScore, Row.CodyScore);
				break;
				case EHazeChapterMinigameScoreType::TimeElapsed:
					BP_SetBestTime(Row.MayScore, Row.CodyScore);
				break;
			}

			if(bHasTickedForSound)
				GetAudioManager().UI_OnSelectionChanged();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_InitializeGlobalStats() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnSelectedMinigameChanged(UMinigamePickerRow SelectedRow) {}

	UFUNCTION(BlueprintEvent)
	void BP_ClearScore() {}

	UFUNCTION(BlueprintEvent)
	void BP_SetHighScore(int MayHighScore, int CodyHighScore) {}

	UFUNCTION(BlueprintEvent)
	void BP_SetRoundsWon(int MayRoundsWon, int CodyRoundsWon) {}

	UFUNCTION(BlueprintEvent)
	void BP_SetBestTime(int MayBestTime, int CodyBestTime) {}

	UFUNCTION(BlueprintPure)
	UMinigamePickerRow GetSelectedRow()
	{
		if (SelectedIndex == -1)
			return nullptr;
		return Rows[SelectedIndex];
	}

	FHazeProgressPointRef GetSelectedMinigame() property
	{
		if (SelectedIndex == -1)
			return FHazeProgressPointRef();
		return Rows[SelectedIndex].MinigameChapter.ProgressPoint;
	}

	UFUNCTION(BlueprintPure)
	bool CanBrowseMinigame(int Direction)
	{
		if (Direction == 0)
			return false;
		if (!CanControlSelection())
			return false;
		for (int i = SelectedIndex + Direction; i >= 0 && i < Rows.Num(); i += Direction)
		{
			if (Rows[i].bIsUnlocked)
				return true;
		}
		return false;
	}

	UFUNCTION()
	void BrowseMinigame(int Direction)
	{
		if (Direction == 0)
			return;
		if (!CanControlSelection())
			return;
		for (int i = SelectedIndex + Direction; i >= 0 && i < Rows.Num(); i += Direction)
		{
			if (Rows[i].bIsUnlocked)
			{
				SelectMinigame(Rows[i].MinigameChapter.ProgressPoint, true);
				Game::NarrateText(Rows[i].MinigameChapter.Name);
				break;
			}
		}
	}

	void SelectMinigame(FHazeProgressPointRef Ref, bool bNotify)
	{
		SelectedIndex = -1;
		for (int i = 0, Count = Rows.Num(); i < Count; ++i)
		{
			auto Row = Rows[i];
			if (Row.MinigameChapter.ProgressPoint.Name == Ref.Name
				&& Row.MinigameChapter.ProgressPoint.InLevel == Ref.InLevel)
			{
				Row.bIsSelected = true;
				ContainerList.ScrollWidgetIntoView(Row, AnimateScroll = false, Padding = 50.f);
				SelectedIndex = i;
			}
			else
			{
				Row.bIsSelected = false;
			}
		}

		UpdateSelectedMinigame();
		if (bNotify)
			OnMinigameSelected.Broadcast(Ref);
	}

	void ScrollToSelection()
	{
		auto Row = GetSelectedRow();
		if (Row != nullptr)
			ContainerList.ScrollWidgetIntoView(Row, AnimateScroll = false, Padding = 50.f);
	}

	void Scroll(float Amount)
	{
		ContainerList.ScrollOffset = FMath::Clamp(ContainerList.ScrollOffset + Amount, 0.f, ContainerList.ScrollOffsetOfEnd);
	}

	UFUNCTION(BlueprintPure)
	bool CanControlSelection()
	{
		// In the lobby only the host can select a chapter
		if (bIsLobby)
		{
			if (!Network::HasWorldControl())
				return false;
		}

		return true;
	}
};