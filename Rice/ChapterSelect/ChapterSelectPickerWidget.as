import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

event void FOnChapterSelectChanged();
event void FOnSubChapterPressed(UChapterSelectSubChapterWidget Widget);

class UChapterSelectSubChapterWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeChapter Chapter;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsSelected = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsUnlocked = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsHovered = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bClickable = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int TotalMinigames = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int UnlockedMinigames = 0;

	UPROPERTY()
	FOnSubChapterPressed OnPressed;

	private bool bHasTickedForSound = false;
	private int InternalMouseOverCount = 0;

	void Update()
	{
		if (Chapter.bIsMinigame)
			bIsUnlocked = Save::IsMinigameUnlocked(Chapter.MinigameId);
		else
			bIsUnlocked = true;

		BP_Update();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Update() {}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry Geom, FPointerEvent MouseEvent)
	{
		if (bClickable)
		{
			bIsHovered = true;
			Game::NarrateText(Chapter.Name);
		}

		if(bHasTickedForSound)
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
			if (bIsHovered && bClickable && bIsUnlocked)
				OnPressed.Broadcast(this);
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		bHasTickedForSound = true;
	}

	UFUNCTION()
	void ResetMouseOverRTPC()
	{
		GetAudioManager().MenuWidgetMouseHoverSoundCount --;
		InternalMouseOverCount --;
	}
};

class UChapterSelectPickerWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsLobby = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UHazeChapterDatabase ChapterDatabase;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeChapter SelectedChapter;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeChapterGroup SelectedGroup;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<FHazeChapter> ChaptersInGroup;
	TArray<int> ChapterMinigameCounts;
	TArray<int> ChapterMinigamesUnlocked;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int GroupTotalMinigames = 0;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	int GroupUnlockedMinigames = 0;
	UPROPERTY()
	bool bShowMinigames = false;

	UPROPERTY()
	FOnChapterSelectChanged OnChapterSelectChanged;

	TArray<UChapterSelectSubChapterWidget> SubChapters;
	int CurrentGroupIndex = -1;
	int CurrentChapterIndex = -1;
	private bool bHasTickedForSound = false;

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

	UFUNCTION(BlueprintEvent)
	void BP_UpdateSelectedChapter() {}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateSelectedGroup() {}

	private void SelectChapterInternal(int ChapterIndex)
	{
		if (ChapterIndex == CurrentChapterIndex)
			return;
		if (ChapterIndex == -1)
			return;

		FHazeChapter NewChapter = ChapterDatabase.GetChapterByIndex(ChapterIndex);
		int NewGroupIndex = ChapterDatabase.GetChapterGroupIndex(NewChapter);
		if (NewGroupIndex == -1)
			return;

		CurrentChapterIndex = ChapterIndex;
		SelectedChapter = NewChapter;

		if (NewGroupIndex != CurrentGroupIndex)
		{
			CurrentGroupIndex = NewGroupIndex;
			SelectedGroup = ChapterDatabase.GetChapterGroupByIndex(CurrentGroupIndex);
			ChaptersInGroup.Empty();
			ChapterMinigamesUnlocked.Empty();
			ChapterMinigameCounts.Empty();
			GroupTotalMinigames = 0;
			GroupUnlockedMinigames = 0;

			int CurMinigames = 0;
			int CurUnlockedMinigames = 0;

			for (const FHazeChapter& Chapter : ChapterDatabase.GetChaptersInGroup(CurrentGroupIndex))
			{
				if (Chapter.bIsMinigame)
				{
					GroupTotalMinigames += 1;
					CurMinigames += 1;
					if (Save::IsMinigameUnlocked(Chapter.MinigameId))
					{
						GroupUnlockedMinigames += 1;
						CurUnlockedMinigames += 1;
					}

					if (!bShowMinigames)
						continue;
				}

				if (ChaptersInGroup.Num() != 0)
				{
					ChapterMinigameCounts.Add(CurMinigames);
					ChapterMinigamesUnlocked.Add(CurUnlockedMinigames);
					CurMinigames = 0;
					CurUnlockedMinigames = 0;
				}

				ChaptersInGroup.Add(Chapter);
			}

			ChapterMinigameCounts.Add(CurMinigames);
			ChapterMinigamesUnlocked.Add(CurUnlockedMinigames);

			UpdateSubChapters();
			BP_UpdateSelectedGroup();

			if(bHasTickedForSound)
				GetAudioManager().UI_ChapterSelectUpdateLevel();
		}
		else
			GetAudioManager().UI_ChapterSelectUpdateProgressPoint();

		UpdateSelectedSubChapter();
		BP_UpdateSelectedChapter();
		OnChapterSelectChanged.Broadcast();
	}

	FString GetNarrationString(bool bIncludeGroup)
	{
		FString Narration = bIncludeGroup ? SelectedGroup.GroupName.ToString() + ", " : "";
		Narration += SelectedChapter.Name.ToString() + ", ";
		return  Narration;
	}

	UFUNCTION(BlueprintEvent)
	void BP_RemoveSubChapter(UChapterSelectSubChapterWidget Widget) {}

	UFUNCTION(BlueprintEvent)
	UChapterSelectSubChapterWidget BP_AddSubChapter() { return nullptr; }

	UFUNCTION(BlueprintPure)
	UChapterSelectSubChapterWidget GetSelectedSubChapter()
	{
		if (SubChapters.Num() == 0)
			return nullptr;

		for (auto SubChapter : SubChapters)
		{
			if (SubChapter.bIsSelected)
				return SubChapter;
		}

		return SubChapters[0];
	}

	private void UpdateSubChapters()
	{
		int NewCount = ChaptersInGroup.Num();
		int OldCount = SubChapters.Num();

		for (int i = NewCount; i < OldCount; ++i)
			BP_RemoveSubChapter(SubChapters[i]);

		SubChapters.SetNum(NewCount);

		for (int i = OldCount; i < NewCount; ++i)
		{
			SubChapters[i] = BP_AddSubChapter();
			SubChapters[i].bClickable = CanControlSelection();
			SubChapters[i].OnPressed.AddUFunction(this, n"OnSubChapterClicked");
		}

		for (int i = 0; i < NewCount; ++i)
		{
			SubChapters[i].Chapter = ChaptersInGroup[i];
			SubChapters[i].UnlockedMinigames = ChapterMinigamesUnlocked[i];
			SubChapters[i].TotalMinigames = ChapterMinigameCounts[i];
			SubChapters[i].Update();
		}

		UpdateSelectedSubChapter();
	}

	UFUNCTION()
	private void OnSubChapterClicked(UChapterSelectSubChapterWidget Widget)
	{
		if (CanControlSelection())
			SelectChapter(Widget.Chapter.ProgressPoint);
	}

	private void UpdateSelectedSubChapter()
	{
		for (int i = 0, Count = SubChapters.Num(); i < Count; ++i)
		{
			SubChapters[i].bIsSelected = (
				ChaptersInGroup[i].ProgressPoint.InLevel == SelectedChapter.ProgressPoint.InLevel
				&& ChaptersInGroup[i].ProgressPoint.Name == SelectedChapter.ProgressPoint.Name
			);
			SubChapters[i].SetVisibility(
				(Save::IsChapterSelectUnlocked(SubChapters[i].Chapter.ProgressPoint)
					|| SubChapters[i].bIsSelected)
				? ESlateVisibility::Visible
				: ESlateVisibility::Collapsed
			);
		}
	}

	UFUNCTION()
	void SelectChapter(FHazeProgressPointRef ProgressPoint)
	{
		SelectChapterInternal(ChapterDatabase.GetChapterIndexForProgressPoint(ProgressPoint));
	}

	UFUNCTION(BlueprintPure)
	bool CanNavigateGroup(int Direction)
	{
		if (!CanControlSelection())
			return false;
		if (CurrentGroupIndex + Direction < 0)
			return false;
		if (CurrentGroupIndex + Direction >= ChapterDatabase.GetChapterGroupCount())
			return false;

		const FHazeChapterGroup& Group = ChapterDatabase.GetChapterGroupByIndex(CurrentGroupIndex + Direction);
		if (!Save::IsChapterSelectUnlocked(Group.ProgressPoint))
			return false;

		return true;
	}

	UFUNCTION()
	void NavigateGroup(int Direction)
	{
		if (!CanNavigateGroup(Direction))
			return;

		const FHazeChapterGroup& Group = ChapterDatabase.GetChapterGroupByIndex(CurrentGroupIndex + Direction);
		SelectChapterInternal(ChapterDatabase.GetChapterIndexForProgressPoint(Group.ProgressPoint));
		Game::NarrateString(GetNarrationString(true));
	}

	UFUNCTION(BlueprintPure)
	bool GetChapterNavigateOffset(int Direction, int& OutOffset)
	{
		if (!CanControlSelection())
			return false;

		OutOffset = Direction;
		while (true)
		{
			if (CurrentChapterIndex + OutOffset < 0)
				return false;
			if (CurrentChapterIndex + OutOffset >= ChapterDatabase.GetChapterCount())
				return false;

			const FHazeChapter& Chapter = ChapterDatabase.GetChapterByIndex(CurrentChapterIndex + OutOffset);
			if (!Save::IsChapterSelectUnlocked(Chapter.ProgressPoint))
				return false;

			int ChapterGroup = ChapterDatabase.GetChapterGroupIndex(Chapter);
			if (ChapterGroup != CurrentGroupIndex)
				return false;

			if (Chapter.bIsMinigame)
			{
				if (!bShowMinigames || !Save::IsMinigameUnlocked(Chapter.MinigameId))
				{
					OutOffset += FMath::Sign(Direction);
					continue;
				}
			}

			break;
		}

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool CanNavigateChapter(int Direction)
	{
		if (!CanControlSelection())
			return false;

		int Offset = 0;
		return GetChapterNavigateOffset(Direction, Offset);
	}

	UFUNCTION()
	void NavigateChapter(int Direction)
	{
		int Offset = 0;
		if (!GetChapterNavigateOffset(Direction, Offset))
			return;

		SelectChapterInternal(CurrentChapterIndex + Offset);
		Game::NarrateString(GetNarrationString(false));
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		bHasTickedForSound = true;
	}

};