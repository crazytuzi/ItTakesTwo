
event void FOnCreditsFinishedPlaying();

struct FCreditsSection
{
	UPROPERTY(meta = (AllowAbstract = false))
	TSubclassOf<UCreditsSectionWidget> SectionType;
	UPROPERTY()
	FString Header;
	UPROPERTY(Meta = (MultiLine = true))
	FString Text;
	UPROPERTY()
	int ExtraSpacingBefore = 0;
	UPROPERTY()
	int ExtraSpacingAfter = 0;
};

class UCreditsData : UDataAsset
{
	UPROPERTY()
	TArray<FCreditsSection> Sections;
};

struct FActiveCreditsSection
{
	UCreditsSectionWidget Widget;
	UCanvasPanelSlot Slot;
	int StartPosition = 0;
	int Height = 0;
	bool bDisplaying = false;
};

struct FActiveTimedCredits
{
	int StartPosition = 0;
	bool bStarted = false;
	float TimeRemaining = 0.f;
	UCreditsSectionWidget Widget;
};

class UCreditsWidget : UHazeUserWidget
{
	UPROPERTY()
	TArray<UCreditsData> AllCredits;

	UPROPERTY()
	float ScrollSpeed = 100.f;

	UPROPERTY()
	int SectionSpacing = 70;

	UPROPERTY()
	FOnCreditsFinishedPlaying OnCreditsFinishedPlaying;

	UPROPERTY(NotEditable)
	UCanvasPanel CreditsCanvas;

	float CurrentPosition = 0.f;
	TArray<FActiveCreditsSection> ActiveCredits;
	TArray<FActiveTimedCredits> ActiveTimedCredits;
	bool bPlaying = false;
	UCreditsData CurrentAsset;

	int CheckCooldown = 0;
	int AssetIndex = -1;
	int SectionIndex = -1;

	void AddSection(FCreditsSection Section)
	{
		if (!Section.SectionType.IsValid())
			return;

		auto Widget = Cast<UCreditsSectionWidget>(Widget::CreateWidget(this, Section.SectionType));
		Widget.Section = Section;
		Widget.AddToCredits(this);
	}

	UFUNCTION()
	void AddScrollingCredits(UCreditsSectionWidget Widget)
	{
		FActiveCreditsSection ActiveSection;
		ActiveSection.Widget = Widget;
		ActiveSection.StartPosition = GetStartPosition() + Widget.Section.ExtraSpacingBefore + Widget.ExtraSpacingBefore;
		ActiveSection.Slot = CreditsCanvas.AddChildToCanvas(Widget);
		ActiveSection.Height = 500;

		FAnchors Anchors;
		Anchors.Minimum.X = 0.f;
		Anchors.Maximum.X = 1.f;
		Anchors.Minimum.Y = 1.f;
		Anchors.Maximum.Y = 1.f;
		ActiveSection.Slot.SetAnchors(Anchors);

		ActiveSection.Slot.SetAlignment(FVector2D(0.f, 0.f));
		ActiveSection.Slot.SetAutoSize(true);

		ActiveCredits.Add(ActiveSection);
	}

	UFUNCTION()
	void AddTimedCredits(UCreditsSectionWidget Widget, float Duration)
	{
		FActiveTimedCredits ActiveSection;
		ActiveSection.TimeRemaining = Duration;
		ActiveSection.Widget = Widget;
		ActiveSection.StartPosition = GetStartPosition() + Widget.Section.ExtraSpacingBefore + Widget.ExtraSpacingBefore;

		auto TimedSlot = CreditsCanvas.AddChildToCanvas(Widget);
		TimedSlot.SetZOrder(-100);
		Widget.SetVisibility(ESlateVisibility::Hidden);

		FAnchors Anchors;
		Anchors.Minimum.X = 0.f;
		Anchors.Maximum.X = 1.f;
		Anchors.Minimum.Y = 0.f;
		Anchors.Maximum.Y = 1.f;
		TimedSlot.SetAnchors(Anchors);

		FMargin Offset;
		Offset.Left = 0.f;
		Offset.Right = 0.f;
		Offset.Top = 0.f;
		Offset.Bottom = 0.f;
		TimedSlot.SetOffsets(Offset);

		TimedSlot.SetAlignment(FVector2D(0.f, 0.f));

		ActiveTimedCredits.Add(ActiveSection);
	}

	UFUNCTION()
	void PlayCreditsFromStart()
	{
		ClearCredits();
		CurrentPosition = 0;
		AssetIndex = -1;
		SectionIndex = -1;
		CurrentAsset = nullptr;
		bPlaying = true;
	}

	void ClearCredits()
	{
		for (FActiveCreditsSection& Section : ActiveCredits)
		{
			if (Section.Widget != nullptr)
				Section.Widget.RemoveFromParent();
		}
		ActiveCredits.Empty();
	}

	int GetStartPosition()
	{
		if (ActiveCredits.Num() == 0)
		{
			return FMath::FloorToInt(CurrentPosition);
		}
		else
		{
			const FActiveCreditsSection& LastSection = ActiveCredits.Last();
			return LastSection.StartPosition + LastSection.Height + LastSection.Widget.Section.ExtraSpacingAfter + LastSection.Widget.ExtraSpacingAfter + SectionSpacing;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		if (!bPlaying)
			return;

		// Scroll the cumulative credits position
		if (!Game::IsPausedForAnyReason())
			CurrentPosition += (DeltaTime * ScrollSpeed);
		int RenderPosition = FMath::FloorToInt(CurrentPosition);

		// Update desired for all active credits
		for (FActiveCreditsSection& Section : ActiveCredits)
			Section.Height = FMath::Max(Section.Widget.DesiredSize.Y, 10.f);

		// Update positions on canvas
		int ViewHeight = MyGeometry.LocalSize.Y;
		for (int i = 0, Count = ActiveCredits.Num(); i < Count; ++i)
		{
			FActiveCreditsSection& Section = ActiveCredits[i];

			// Remove sections that have completely scrolled off
			if (RenderPosition - ViewHeight > Section.StartPosition + Section.Height)
			{
				Section.Widget.BP_StopDisplaying();
				ActiveCredits.RemoveAt(i);
				--i; --Count;
				continue;
			}

			if (!Section.bDisplaying && RenderPosition >= Section.StartPosition)
			{
				Section.Widget.BP_StartDisplaying();
				Section.bDisplaying = true;
			}

			FMargin Offset;
			Offset.Left = 0.f;
			Offset.Right = 0.f;
			Offset.Top = Section.StartPosition - RenderPosition;
			Offset.Bottom = Offset.Top + Section.Height;
			Section.Slot.SetOffsets(Offset);
		}

		// Update timed sections
		for (int i = 0, Count = ActiveTimedCredits.Num(); i < Count; ++i)
		{
			FActiveTimedCredits& Section = ActiveTimedCredits[i];

			// Start the timed section when the position is reached
			if (!Section.bStarted)
			{
				if (Section.StartPosition < RenderPosition)
				{
					Section.bStarted = true;
					Section.Widget.SetVisibility(ESlateVisibility::HitTestInvisible);
					Section.Widget.BP_StartDisplaying();
				}
				else
				{
					continue;
				}
			}

			// Remove sections that are finished
			Section.TimeRemaining -= DeltaTime;
			if (Section.TimeRemaining < 0.f)
			{
				Section.Widget.BP_StopDisplaying();
				ActiveTimedCredits.RemoveAt(i);
				--i; --Count;
				continue;
			}
		}

		// Check if we should add the next credits section
		CheckCooldown -= 1;
		if (CheckCooldown <= 0)
		{
			if (ActiveCredits.Num() == 0 || ActiveCredits.Last().StartPosition <= RenderPosition)
			{
				if (CurrentAsset != nullptr)
				{
					if (CurrentAsset.Sections.IsValidIndex(SectionIndex+1))
					{
						SectionIndex += 1;
						CheckCooldown = 5;
						AddSection(CurrentAsset.Sections[SectionIndex]);
					}
					else
					{
						CurrentAsset = nullptr;
					}
				}

				if (CurrentAsset == nullptr && AllCredits.IsValidIndex(AssetIndex+1))
				{
					AssetIndex += 1;
					SectionIndex = -1;
					CurrentAsset = AllCredits[AssetIndex];
				}

				if (CurrentAsset == nullptr && ActiveCredits.Num() == 0 && ActiveTimedCredits.Num() == 0)
				{
					// Credits are finished
					Print("Credits are finished");
					bPlaying = false;
					OnCreditsFinishedPlaying.Broadcast();
				}
			}
		}
	}
};

UCLASS(Abstract)
class UCreditsSectionWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FCreditsSection Section;

	UPROPERTY()
	int ExtraSpacingBefore = 0;

	UPROPERTY()
	int ExtraSpacingAfter = 0;

	void AddToCredits(UCreditsWidget Credits)
	{
		BP_AddToCredits(Credits);
	}

	UFUNCTION(BlueprintEvent)
	void BP_AddToCredits(UCreditsWidget Credits) {}

	UFUNCTION(BlueprintEvent)
	void BP_StartDisplaying() {}

	UFUNCTION(BlueprintEvent)
	void BP_StopDisplaying()
	{
		RemoveFromParent();
	}
};

UCLASS(Abstract)
class UCreditsSection_CustomWidget : UCreditsSectionWidget
{
	void AddToCredits(UCreditsWidget Credits) override
	{
		Super::AddToCredits(Credits);
		Credits.AddScrollingCredits(this);
	}
};

UCLASS(Abstract)
class UCreditsSection_TextBlob : UCreditsSectionWidget
{
	void AddToCredits(UCreditsWidget Credits) override
	{
		Super::AddToCredits(Credits);
		Credits.AddScrollingCredits(this);
	}
};

UCLASS(Abstract)
class UCreditsSection_Columns : UCreditsSectionWidget
{
	TArray<FString> ColumnText;

	void ParseColumnText()
	{
		TArray<FString> Lines;
		Section.Text.ParseIntoArray(Lines, "\n", bCullEmpty=false);

		TArray<FString> Columns;
		int LineCount = 0;
		for (const FString& Line : Lines)
		{
			Columns.Reset();
			Line.Replace("%","\t").ParseIntoArray(Columns, "\t", bCullEmpty=false);

			// Add new columns with empty lines for all previous cines
			while (Columns.Num() > ColumnText.Num())
			{
				FString NewLines;
				NewLines.Reserve(LineCount+16);
				for (int i = 0; i < LineCount; ++i)
					NewLines += "\n";
				ColumnText.Add(NewLines);
				ColumnText[ColumnText.Num()-1].Reserve(1024);
			}

			// Set text for all columns
			for (int i = 0, Count = ColumnText.Num(); i < Count; ++i)
			{
				if (Columns.IsValidIndex(i))
					ColumnText[i] += Columns[i].TrimEnd()+"\n";
				else
					ColumnText[i] += "\n";
			}

			LineCount += 1;
		}

		// Remove the extra linebreak from the end
		for (int i = 0, Count = ColumnText.Num(); i < Count; ++i)
			ColumnText[i] = ColumnText[i].TrimEnd();
	}

	void AddToCredits(UCreditsWidget Credits) override
	{
		ParseColumnText();
		Super::AddToCredits(Credits);
		Credits.AddScrollingCredits(this);
	}

	UFUNCTION(BlueprintPure)
	FString GetTextForColumn(int ColumnIndex)
	{
		if (!ColumnText.IsValidIndex(ColumnIndex))
			return "";
		return ColumnText[ColumnIndex];
	}
};

UCLASS(Abstract)
class UCreditsSection_Timed : UCreditsSectionWidget
{
	UPROPERTY()
	float Duration = 10.f;

	void AddToCredits(UCreditsWidget Credits) override
	{
		Super::AddToCredits(Credits);
		Credits.AddTimedCredits(this, Duration);
	}
};