import Rice.TemporalLog.TemporalLogComponent;
import Vino.Camera.Actors.StaticCamera;

struct FTemporalLogTimer
{
	double StartTime;
	FString Text;
	bool bPrint;

	FTemporalLogTimer(const FString& InText, bool InPrint = true)
	{
		StartTime = Time::GetPlatformTimeSeconds();
		Text = InText;
		bPrint = InPrint;
	}

	~FTemporalLogTimer()
	{
		double EndTime = Time::GetPlatformTimeSeconds();
		//if (bPrint)
			//Print("[PERF] "+Text+" = "+((EndTime - StartTime)*1000)+"ms");
	}
}

struct FTemporalValueDetails
{
	UPROPERTY()
	FName Name;
	UPROPERTY()
	FString Value;
	UPROPERTY()
	bool bChanged = false;
	UPROPERTY()
	bool bWatched = false;
}

UCLASS(Abstract)
class UTemporalValueWidget : UHazeUserWidget
{
	UTemporalLogDebugMenu Menu;
	FName ValueName;

	UPROPERTY()
	bool bWatched = false;

	UFUNCTION(BlueprintEvent)
	void Update(FTemporalValueDetails Details)
	{
	}

	UFUNCTION()
	void ToggleWatched()
	{
		if (Menu.WatchedValueName == ValueName)
			Menu.ClearWatchedValue();
		else
			Menu.SetWatchedValue(ValueName);
	}

	UFUNCTION()
	void ToggleDrawing()
	{
		if (!CanDraw())
			return;
		if (IsDrawing())
			SetDraw(false);
		else
			SetDraw(true);
		Menu.UpdateEntry();
	}

	UFUNCTION(BlueprintPure)
	bool CanDraw()
	{
		if (Menu.Entry == nullptr)
			return false;
		return Menu.Entry.Visualizations.Contains(ValueName);
	}

	UFUNCTION(BlueprintPure)
	bool IsDrawing()
	{
		if (Menu.Entry == nullptr)
			return false;

		// Check if we're drawing by default or not
		bool bWantsDraw = false;
		for (auto& Vis : Menu.Entry.Visualizations)
		{
			if (Vis.Key != ValueName)
				continue;
			for (auto& VisEvt : Vis.Value.Visualizations)
			{
				if (VisEvt.bDrawByDefault)
				{
					bWantsDraw = true;
					break;
				}
			}
		}

		// Check if we're included from drawing
		for (FTemporalLogEntryRef& Ref : Menu.IncludedDraws)
		{
			if (Ref.ObjectName == Menu.Entry.ObjectName
				&& Ref.ValueName == ValueName)
			{
				bWantsDraw = true;
			}
		}

		// Check if we're excluded from drawing
		for (FTemporalLogEntryRef& Ref : Menu.ExcludedDraws)
		{
			if (Ref.ObjectName == Menu.Entry.ObjectName
				&& Ref.ValueName == ValueName)
			{
				return false;
			}
		}

		return bWantsDraw;
	}

	UFUNCTION()
	void SetDraw(bool bDraw)
	{
		if (bDraw)
		{
			for (int i = 0, Count = Menu.ExcludedDraws.Num(); i < Count; ++i)
			{
				FTemporalLogEntryRef& Ref = Menu.ExcludedDraws[i];
				if (Ref.ObjectName == Menu.Entry.ObjectName && Ref.ValueName == ValueName)
				{
					Menu.ExcludedDraws.RemoveAt(i);
					--i; --Count;
					continue;
				}
			}

			FTemporalLogEntryRef MyRef;
			MyRef.ObjectName = Menu.Entry.ObjectName;
			MyRef.ValueName = ValueName;
			Menu.IncludedDraws.Add(MyRef);
			Menu.SaveConfig();
		}
		else
		{
			for (int i = 0, Count = Menu.IncludedDraws.Num(); i < Count; ++i)
			{
				FTemporalLogEntryRef& Ref = Menu.IncludedDraws[i];
				if (Ref.ObjectName == Menu.Entry.ObjectName && Ref.ValueName == ValueName)
				{
					Menu.IncludedDraws.RemoveAt(i);
					--i; --Count;
					continue;
				}
			}

			FTemporalLogEntryRef MyRef;
			MyRef.ObjectName = Menu.Entry.ObjectName;
			MyRef.ValueName = ValueName;
			Menu.ExcludedDraws.Add(MyRef);
			Menu.SaveConfig();
		}
	}
};

UCLASS(Abstract)
class UTemporalCallbackWidget : UHazeUserWidget
{
	UTemporalLogDebugMenu Menu;
	FTemporalLogCallback Callback;

	UFUNCTION(BlueprintEvent)
	void Update(FString Label)
	{

	}

	UFUNCTION()
	void ExecuteCallback()
	{
		Callback.Callback.Broadcast(Menu.DebugActor, Menu.Frame);
	}
};

class UTemporalTimelineWidget : UHazeUserWidget
{
	UTemporalLogDebugMenu Menu;

	UPROPERTY()
	USlateBrushAsset Brush;

	int HoveredIndex = -1;
	bool bMouseHeld = false;

	bool bIsZooming = false;
	int ZoomStartFrame = 0;

	float GetStartTime() const property
	{
		if (Menu == nullptr)
			return 0.f;
		UTemporalLogFrame FirstFrame = Menu.Component.Frames[0];
		if (Menu.ZoomRangeStart != -1)
		{
			if (Menu.Component.Frames.IsValidIndex(Menu.ZoomRangeStart))
				FirstFrame = Menu.Component.Frames[Menu.ZoomRangeStart];
		}
		else if (Menu.LimitFramesShown != -1)
		{
			FirstFrame = Menu.Component.Frames[FMath::Max(0, Menu.Component.Frames.Num() - Menu.LimitFramesShown)];
		}

		return FirstFrame.GameTime - FirstFrame.DeltaTime;
	}

	int GetFirstConsideredFrame() property
	{
		if (Menu.ZoomRangeStart != -1)
			return Menu.ZoomRangeStart;
		else if (Menu.LimitFramesShown != -1)
			return FMath::Max(0, Menu.Component.Frames.Num() - Menu.LimitFramesShown);
		return 0;
	}

	float GetEndTime() const property
	{
		if (Menu == nullptr)
			return 1.f;
		UTemporalLogFrame LastFrame = Menu.Component.Frames.Last();
		if (Menu.ZoomRangeEnd != -1)
		{
			if (Menu.Component.Frames.IsValidIndex(Menu.ZoomRangeEnd))
				LastFrame = Menu.Component.Frames[Menu.ZoomRangeEnd];
		}
		return LastFrame.GameTime;
	}

	float GetTimePos(float Time) const
	{
		float TimePct = (Time - StartTime) / (EndTime - StartTime);
		return TimePct * (CachedGeometry.LocalSize.X - 10.f) + 5.f;
	}

	float GetDurationSize(float Time) const
	{
		return FMath::Max(Time / (EndTime - StartTime) * (CachedGeometry.LocalSize.X - 10.f), 2.f);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geometry, FPointerEvent MouseEvent)
	{
		if (Menu == nullptr)
			return FEventReply::Handled();
		UpdateHovered(Geometry, MouseEvent);

		if (MouseEvent.EffectingButton == EKeys::MiddleMouseButton)
		{
			Menu.StartPlaying(bReverse = MouseEvent.IsShiftDown());
		}
		else if (MouseEvent.EffectingButton == EKeys::RightMouseButton)
		{
			if (HoveredIndex != -1)
			{
				ZoomStartFrame = HoveredIndex;
				bIsZooming = true;
			}
		}
		else
		{
			bMouseHeld = true;
		}
		return FEventReply::Handled().PreventThrottling();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geometry, FPointerEvent MouseEvent)
	{
		if (Menu == nullptr)
			return FEventReply::Handled();

		if (MouseEvent.EffectingButton == EKeys::MiddleMouseButton)
		{
			Menu.StopPlaying();
		}
		if (bIsZooming)
		{
			if (HoveredIndex != -1)
			{
				Menu.SetZoomRange(FMath::Min(ZoomStartFrame, HoveredIndex), FMath::Max(ZoomStartFrame, HoveredIndex));
			}
			bIsZooming = false;
		}
		else
		{
			bMouseHeld = false;
		}
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry Geometry, FPointerEvent MouseEvent)
	{
		if (Menu == nullptr)
			return FEventReply::Handled();
		UpdateHovered(Geometry, MouseEvent);
		return FEventReply::Handled();
	}

	void UpdateHovered(FGeometry Geometry, FPointerEvent MouseEvent)
	{
		FVector2D ScreenPos = Input::PointerEvent_GetScreenSpacePosition(MouseEvent);
		FVector2D LocalPos = Geometry.AbsoluteToLocal(ScreenPos);

		float HoveredPct = (LocalPos.X - 5.f) / (Geometry.LocalSize.X - 10.f);
		float HoveredTime = StartTime + HoveredPct * (EndTime - StartTime);

		HoveredIndex = -1;
		for (int i = GetFirstConsideredFrame(), Count = Menu.Component.Frames.Num(); i < Count; ++i)
		{
			float FrameDelta = Menu.Component.Frames[i].DeltaTime;
			float FrameTime = Menu.Component.Frames[i].GameTime;

			if (FrameTime - FrameDelta > HoveredTime)
				continue;
			if (FrameTime < HoveredTime)
				continue;

			HoveredIndex = i;
			break;
		}

		if (bMouseHeld && HoveredIndex != -1)
			Menu.SelectFrameByIndex(HoveredIndex);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		HoveredIndex = -1;
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		if (Menu == nullptr)
			return;

		float PaintStart = GetStartTime();
		float PaintEnd = GetEndTime();

		// Draw the timeline background
		FGeometry Geometry = GetCachedGeometry();
		WidgetBlueprint::DrawBox(Context,
			FVector2D(5.f, 5.f),
			Geometry.LocalSize - FVector2D(10.f, 10.f), Brush,
			FLinearColor(0.1f, 0.1f, 0.1f, 1.f));

		// Draw the selected frame
		auto Frame = Menu.Frame;
		WidgetBlueprint::DrawBox(Context,
			FVector2D(GetTimePos(Frame.GameTime - Frame.DeltaTime), 5.f),
			FVector2D(GetDurationSize(Frame.DeltaTime), Geometry.LocalSize.Y - 10.f),
			Brush, FLinearColor(0.1f, 0.5f, 0.1f, 1.f));

		// Draw the changed overlays
		for (int i = 0, Count = Menu.WatchChangeTimes.Num(); i < Count; i += 2)
		{
			float ChangeStart = Menu.WatchChangeTimes[i];
			float ChangeEnd = Menu.WatchChangeTimes[i+1];

			if (ChangeEnd < PaintStart)
				continue;
			if (ChangeStart > PaintEnd)
				continue;

			ChangeStart = FMath::Max(ChangeStart, PaintStart);
			ChangeEnd = FMath::Min(ChangeEnd, PaintEnd);

			WidgetBlueprint::DrawBox(Context,
				FVector2D(GetTimePos(ChangeStart), Geometry.LocalSize.Y * 0.5f),
				FVector2D(GetDurationSize(ChangeEnd - ChangeStart), Geometry.LocalSize.Y * 0.5f - 5.f),
				Brush, FLinearColor(1.f, 0.2f, 0.2f, 0.4f));
		}

		// Draw the entry object color line
		for (int i = 0, Count = Menu.ColorSegments.Num(); i < Count; ++i)
		{
			auto& Seg = Menu.ColorSegments[i];
			if (Seg.EndTime < PaintStart)
				continue;
			if (Seg.StartTime > PaintEnd)
				continue;

			float SegStart = FMath::Max(Seg.StartTime, PaintStart);
			float SegEnd = FMath::Min(Seg.EndTime, PaintEnd);
			WidgetBlueprint::DrawBox(Context,
				FVector2D(GetTimePos(SegStart), 5.f),
				FVector2D(GetDurationSize(SegEnd - SegStart), 5.f),
				Brush, Seg.Color);
		}

		// Draw the hovered frame
		if (Menu.Component.Frames.IsValidIndex(HoveredIndex))
		{
			auto HoveredFrame = Menu.Component.Frames[HoveredIndex];
			WidgetBlueprint::DrawBox(Context,
				FVector2D(GetTimePos(HoveredFrame.GameTime - HoveredFrame.DeltaTime), 0.f),
				FVector2D(GetDurationSize(HoveredFrame.DeltaTime), Geometry.LocalSize.Y),
				Brush, FLinearColor(1.f, 1.f, 1.f, 0.2f));
		}

		// Draw overlay for pending zoom range
		if (bIsZooming && HoveredIndex != -1)
		{
			auto StartZoomFrame = Menu.Component.Frames[FMath::Min(ZoomStartFrame, HoveredIndex)];
			auto EndZoomFrame = Menu.Component.Frames[FMath::Max(ZoomStartFrame, HoveredIndex)];

			float ZoomStart = StartZoomFrame.GameTime - StartZoomFrame.DeltaTime;
			WidgetBlueprint::DrawBox(Context,
				FVector2D(GetTimePos(ZoomStart), 0.f),
				FVector2D(GetDurationSize(EndZoomFrame.GameTime - ZoomStart), Geometry.LocalSize.Y),
				Brush, FLinearColor(0.5f, 0.f, 0.5f, 0.25f));
		}
	}
};

UCLASS(Abstract)
class UTemporalEntryWidget : UHazeUserWidget
{
	UPROPERTY()
	bool bSelected = false;

	UTemporalLogDebugMenu Menu;
	UTemporalLogObject Entry;

	UFUNCTION(BlueprintEvent)
	void Update(UTemporalLogObject Entry)
	{
	}

	UFUNCTION()
	void Selected()
	{
		Menu.SelectEntry(Entry);
	}
};

struct FTemporalObjectColorSegment
{
	float StartTime;
	float EndTime;
	FLinearColor Color;
};

struct FTemporalLogEntryRef
{
	UPROPERTY()
	FName ObjectName;
	UPROPERTY()
	FName ValueName;
};

UCLASS(Config = Editor)
class UTemporalLogDebugMenu : UHazeDebugMenuScriptBase
{
	UPROPERTY()
	AHazeActor DebugActor;
	
	UPROPERTY()
	UTemporalLogComponent Component;

	UPROPERTY()
	UTemporalLogFrame Frame;

	UPROPERTY()
	UTemporalLogObject Entry;

	UPROPERTY()
	TSubclassOf<UTemporalValueWidget> ValueWidgetClass;

	UPROPERTY()
	TSubclassOf<UTemporalCallbackWidget> CallbackWidgetClass;

	UPROPERTY()
	TSubclassOf<UTemporalEntryWidget> EntryWidgetClass;

	UPROPERTY()
	TArray<FName> Categories;

	UPROPERTY()
	FName SelectedCategory;

	UPROPERTY()
	int LimitFramesShown = -1;

	UPROPERTY()
	int ZoomRangeStart = -1;

	UPROPERTY()
	int ZoomRangeEnd = -1;

	UPROPERTY()
	int PositionContext = 20;

	private int FrameIndex = -1;
	private TArray<UTemporalValueWidget> ValueWidgets;
	private TArray<UTemporalEntryWidget> EntryWidgets;

	TArray<float> WatchChangeTimes;
	int WatchLastFrame = -1;

	TArray<FTemporalObjectColorSegment> ColorSegments;
	UTemporalLogFrame ColorLastFrame = nullptr;
	bool LastFrameEndedWithColor = false;
	FName LastSegmentColorEntryName;

	FName WatchedValueName;
	FName WatchedObjectName;

	UPROPERTY(Config)
	TArray<FTemporalLogEntryRef> IncludedDraws;
	UPROPERTY(Config)
	TArray<FTemporalLogEntryRef> ExcludedDraws;

	AHazeCameraActor VisualizerCamera;
	bool bVisualizerCameraActive = false;

	AHazeSkeletalMeshActor VisualizerMesh;
	bool bVisualizerMeshActive = false;
	UHazeSkeletalMeshComponentBase VisualizerMeshComp;

	bool bPlayingRight = false;
	bool bPlayingLeft = false;
	float PlayTime = -1.f;

	UFUNCTION()
	void SetActorToDebug(AHazeActor Actor)
	{
		DestroyVisualizations();
		DebugActor = Actor;
		Component = UTemporalLogComponent::Get(Actor);
		LastSegmentColorEntryName = NAME_None;

		// Try to select the same frame we had selected before
		if (Frame != nullptr)
		{
			FrameIndex = GetFrameIndex(Frame.FrameNumber);
			if (FrameIndex == -1)
			{
				Frame = Component.Frames.Last();
				FrameIndex = Component.Frames.Num() - 1;
			}
			else
			{
				Frame = Component.Frames[FrameIndex];
			}
		}
		else
		{
			Frame = Component.Frames.Last();
			FrameIndex = Component.Frames.Num() - 1;
		}

		GetTimeline().Menu = this;
		UpdateFrame();
		UpdateWatch();
	}

	UFUNCTION(BlueprintEvent)
	UHazeTextWigdet GetEntryDetailsWidget() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UPanelWidget GetEntryValueListWidget() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTemporalCallbackWidget GetEntryCallbackWidget() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UPanelWidget GetEntryListWidget() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UComboBoxString GetCategoryBox() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTemporalTimelineWidget GetTimeline() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void UpdateFrameSelector()
	{
	}

	UFUNCTION(BlueprintPure)
	UTemporalLogFrame GetNextFrame() property
	{
		if(Component == nullptr)
			return nullptr;
		if(Component.Frames.IsValidIndex(FrameIndex+1))
			return Component.Frames[FrameIndex+1];
		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	UTemporalLogFrame GetPreviousFrame() property
	{
		if(Component == nullptr)
			return nullptr;
		if(Component.Frames.IsValidIndex(FrameIndex-1))
			return Component.Frames[FrameIndex-1];
		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	int GetFrameIndex(uint FrameNumber)
	{
		for (int i = 0, Count = Component.Frames.Num(); i < Count; ++i)
		{
			if(Component.Frames[i].FrameNumber == FrameNumber)
				return i;
		}
		return -1;
	}

	UFUNCTION(BlueprintPure)
	int GetCurrentFrameNumber() property
	{
		if(Frame == nullptr)
			return -1;
		return int(Frame.FrameNumber);
	}

	UFUNCTION()
	void SelectEntry(UTemporalLogObject NewEntry)
	{
		if(NewEntry == nullptr)
			return;

		for(auto OtherWidget : EntryWidgets)
			OtherWidget.bSelected = (OtherWidget.Entry == NewEntry);
		Entry = NewEntry;
		UpdateEntry();

		if (SelectedCategory != Entry.Category)
		{
			SelectedCategory = Entry.Category;
			UpdateFrame();
		}
	}

	UFUNCTION()
	void SelectCategory(FName Category)
	{
		if (SelectedCategory == Category)
			return;
		if (Category == NAME_None)
			return;
		SelectedCategory = Category;
		UpdateFrame();
	}

	void SelectFrameByIndex(int NewFrameIndex)
	{
		FTemporalLogTimer Timer("Select Frame");
		auto NewFrame = Component.Frames[NewFrameIndex];
		Frame = NewFrame;
		FrameIndex = NewFrameIndex;
		UpdateFrame();
	}

	UFUNCTION()
	void SelectFrame(UTemporalLogFrame NewFrame)
	{
		if (NewFrame == nullptr)
			return;
		SelectFrameByIndex(Component.Frames.FindIndex(NewFrame));
	}

	void ClearWatchedValue()
	{
		WatchedObjectName = NAME_None;
		WatchedValueName = NAME_None;
		UpdateEntry();
		UpdateWatch();
	}

	void UpdateWatch(bool bPartialUpdate = false)
	{
		if (!bPartialUpdate)
		{
			WatchChangeTimes.Reset();
			WatchLastFrame = -1;
		}

		if (WatchedObjectName == NAME_None || WatchedValueName == NAME_None)
			return;

		if (bPartialUpdate && WatchLastFrame >= Component.Frames.Num())
			return;

		FString CurrentValue;
		bool bHaveValue = false;
		bool bHaveChange = false;
		float ChangesStart = 0.f;
		int FrameCount = Component.Frames.Num();

		int StartFrame = bPartialUpdate && WatchLastFrame >= 0 ? WatchLastFrame : 0;
		for (int i = StartFrame; i < FrameCount; ++i)
		{
			auto CheckFrame = Component.Frames[i];

			FString FrameValue;
			auto CheckEntry = CheckFrame.GetObjectByName(WatchedObjectName);
			if (CheckEntry != nullptr)
			{
				CheckEntry.Values.Find(WatchedValueName, FrameValue);
			}

			if (!bHaveValue)
			{
				CurrentValue = FrameValue;
				bHaveValue = true;
			}

			if (bPartialUpdate && i == WatchLastFrame)
				CurrentValue = FrameValue;

			bool bFrameChanged = FrameValue != CurrentValue;
			if (bFrameChanged)
			{
				if (!bHaveChange)
				{
					bHaveChange = true;
					ChangesStart = CheckFrame.GameTime - CheckFrame.DeltaTime;
				}

				CurrentValue = FrameValue;
			}
			else
			{
				if (bHaveChange)
				{
					// Finalize the previous change
					WatchChangeTimes.Add(ChangesStart);
					WatchChangeTimes.Add(CheckFrame.GameTime - CheckFrame.DeltaTime);
					bHaveChange = false;
				}
			}
		}
		
		WatchLastFrame = Component.Frames.Num() - 1;

		if (bHaveChange)
		{
			// Finalize the remaining change
			WatchChangeTimes.Add(ChangesStart);
			WatchChangeTimes.Add(Component.Frames.Last().GameTime);
			bHaveChange = false;
		}
	}

	void UpdateSegmentColor(bool bPartialUpdate = false)
	{
		FTemporalLogTimer Timer("UpdateSegmentColor", !bPartialUpdate);

		if (!bPartialUpdate)
		{
			// Don't update at all if we haven't changed entry
			if (Entry.ObjectName == LastSegmentColorEntryName)
				return;
		}

		if (!bPartialUpdate)
			ColorSegments.Reset();

		if (Entry == nullptr)
			return;

		if (bPartialUpdate && ColorLastFrame == Component.Frames.Last())
			return;

		if (bPartialUpdate && LastFrameEndedWithColor && ColorLastFrame != nullptr)
		{
			auto LastEntry = ColorLastFrame.GetObjectByName(Entry.ObjectName);
			if (LastEntry != nullptr)
			{
				FLinearColor ExtendColor = LastEntry.ObjectColor;
				bool bFound = false;
				bool bFinishedExtending = false;
				for (auto CheckFrame : Component.Frames)
				{
					if (CheckFrame == ColorLastFrame)
						bFound = true;
					if (!bFound)
						continue;

					auto CheckEntry = CheckFrame.GetObjectByName(Entry.ObjectName);
					FLinearColor NewColor = CheckEntry != nullptr ? CheckEntry.ObjectColor : FLinearColor::White;

					if (NewColor != ExtendColor)
					{
						auto& Seg = ColorSegments[ColorSegments.Num() - 1];
						Seg.EndTime = CheckFrame.GameTime - CheckFrame.DeltaTime;

						ColorLastFrame = CheckFrame;
						bFinishedExtending = true;
						break;
					}
				}

				if (!bFinishedExtending)
				{
					ColorLastFrame = Component.Frames.Last();
					LastFrameEndedWithColor = true;

					auto& Seg = ColorSegments[ColorSegments.Num() - 1];
					Seg.EndTime = ColorLastFrame.GameTime - ColorLastFrame.DeltaTime;
					return;
				}
			}
		}

		FLinearColor CurrentColor;
		float ValueSince = 0.f;
		bool bHaveColor = false;

		bool bFoundPartial = false;

		for (auto CheckFrame : Component.Frames)
		{
			if (CheckFrame == ColorLastFrame)
				bFoundPartial = true;
			if (bPartialUpdate && !bFoundPartial)
				continue;

			auto CheckEntry = CheckFrame.GetObjectByName(Entry.ObjectName);
			FLinearColor NewColor = CheckEntry != nullptr ? CheckEntry.ObjectColor : FLinearColor::White;
			bool bColorChanged = NewColor != CurrentColor;

			if (bColorChanged)
			{
				if (bHaveColor)
				{
					FTemporalObjectColorSegment PrevSegment;
					PrevSegment.StartTime = ValueSince;
					PrevSegment.EndTime = CheckFrame.GameTime - CheckFrame.DeltaTime;
					PrevSegment.Color = CurrentColor;
					ColorSegments.Add(PrevSegment);
				}

				CurrentColor = NewColor;
				ValueSince = CheckFrame.GameTime - CheckFrame.DeltaTime;
				bHaveColor = CurrentColor != FLinearColor::White;
			}
		}
		
		ColorLastFrame = Component.Frames.Last();
		LastFrameEndedWithColor = bHaveColor;
		LastSegmentColorEntryName = Entry.ObjectName;

		if (bHaveColor)
		{
			FTemporalObjectColorSegment PrevSegment;
			PrevSegment.StartTime = ValueSince;
			PrevSegment.EndTime = Component.Frames.Last().GameTime;
			PrevSegment.Color = CurrentColor;
			ColorSegments.Add(PrevSegment);
		}
	}

	void SetWatchedValue(FName Value)
	{
		WatchedObjectName = Entry.ObjectName;
		WatchedValueName = Value;
		UpdateEntry();
		UpdateWatch();
	}

	void TryMatchSelectEntry(const TArray<UTemporalLogObject>& Entries, bool bChangeCategory = false)
	{
		UTemporalLogObject NewEntry;
		if (Entry != nullptr)
		{
			FName WantEntryName = Entry.ObjectName;
			for (auto CheckEntry : Entries)
			{
				if (!bChangeCategory && CheckEntry.Category != SelectedCategory)
					continue;

				if (CheckEntry.ObjectName == WantEntryName)
				{
					NewEntry = CheckEntry;
					break;
				}
			}
		}

		if (NewEntry == nullptr && Entries.Num() != 0)
			NewEntry = Entries[0];
		SelectEntry(NewEntry);
	}

	void UpdateFrame()
	{
		FTemporalLogTimer Timer("Update Frame");

		// Filter entry objects
		TArray<UTemporalLogObject> Entries;
		Categories.Reset();

		for (int i = 0, Count = Frame.Objects.Num(); i < Count; ++i)
		{
			auto FrameEntry = Frame.Objects[i];
			Categories.AddUnique(FrameEntry.Category);

			if (FrameEntry.Category == SelectedCategory)
				Entries.Add(FrameEntry);
		}

		// Update categories
		if (!Categories.Contains(SelectedCategory) && Categories.Num() != 0)
		{
			SelectedCategory = Categories[0];
			UpdateFrame();
			return;
		}

		// Update entry widgets
		int EntryCount = Entries.Num();
		int OldCount = EntryWidgets.Num();

		// Remove old value widgets
		for (int i = EntryCount; i < OldCount; ++i)
			EntryWidgets[i].RemoveFromParent();

		EntryWidgets.SetNum(EntryCount);

		// Add new value widgets
		auto EntryList = GetEntryListWidget();
		for (int i = OldCount; i < EntryCount; ++i)
		{
			auto Widget = Cast<UTemporalEntryWidget>(Widget::CreateWidget(this, EntryWidgetClass.Get()));
			Widget.Menu = this;
			EntryWidgets[i] = Widget;

			if (EntryList != nullptr)
				EntryList.AddChild(Widget);
		}

		// Update value widgets
		for (int i = 0; i < EntryCount; ++i)
		{
			auto FrameEntry = Entries[i];
			EntryWidgets[i].Entry = FrameEntry;
			EntryWidgets[i].Update(FrameEntry);
		}

		// Select different entry if mismatching category
		if (!Entries.Contains(Entry))
			TryMatchSelectEntry(Entries, bChangeCategory = false);

		// Update category dropdown
		UComboBoxString CategoryDropdown = GetCategoryBox();
		if(CategoryDropdown != nullptr)
		{
			CategoryDropdown.ClearOptions();
			for (auto Category : Categories)
				CategoryDropdown.AddOption(Category.ToString());
			CategoryDropdown.SetSelectedOption(SelectedCategory.ToString());
		}

		UpdateFrameSelector();
	}

	void UpdateEntry()
	{
		if (Entry == nullptr)
			return;
		FTemporalLogTimer Timer("Update Entry");

		UTemporalLogObject LastFrameEntry = nullptr;
		if (PreviousFrame != nullptr)
		{
			for (auto CheckEntry : PreviousFrame.Objects)
			{
				if (CheckEntry.ObjectName == Entry.ObjectName)
				{
					LastFrameEntry = CheckEntry;
					break;
				}
			}
		}

		// Update details text
		// TODO

		// Update value widgets
		int ValueCount = Entry.Values.Num();
		int OldCount = ValueWidgets.Num();

		// Remove old value widgets
		for (int i = ValueCount; i < OldCount; ++i)
			ValueWidgets[i].RemoveFromParent();

		ValueWidgets.SetNum(ValueCount);

		// Add new value widgets
		auto EntryList = GetEntryValueListWidget();
		for (int i = OldCount; i < ValueCount; ++i)
		{
			auto Widget = Cast<UTemporalValueWidget>(Widget::CreateWidget(this, ValueWidgetClass.Get()));
			Widget.Menu = this;
			ValueWidgets[i] = Widget;

			if (EntryList != nullptr)
				EntryList.AddChild(Widget);
		}

		// Update value widgets
		int i = 0;
		for (auto& Elem : Entry.Values)
		{
			FTemporalValueDetails Details;
			Details.Name = Elem.Key;
			Details.Value = Elem.Value;
			Details.bWatched = Entry.ObjectName == WatchedObjectName && Details.Name == WatchedValueName;

			if (LastFrameEntry == nullptr)
			{
				Details.bChanged = true;
			}
			else
			{
				FString LastFrameValue;
				if (LastFrameEntry.Values.Find(Details.Name, LastFrameValue))
				{
					Details.bChanged = LastFrameValue != Details.Value;
				}
				else
				{
					Details.bChanged = true;
				}
			}

			ValueWidgets[i].ValueName = Details.Name;
			ValueWidgets[i].Update(Details);
			i += 1;
		}

		// Update callback widget
		UTemporalCallbackWidget CallbackWidget = GetEntryCallbackWidget();
		CallbackWidget.Menu = this;
		CallbackWidget.Callback = Entry.Callback;

		if (Entry.Callback.Callback.IsBound())
		{
			CallbackWidget.SetVisibility(ESlateVisibility::Visible);
			CallbackWidget.Update(Entry.Callback.Label);
		}
		else
		{
			CallbackWidget.SetVisibility(ESlateVisibility::Collapsed);
		}

		UpdateSegmentColor();
	}

	UFUNCTION(BlueprintOverride)
	void OnVisibleMenuChanged(bool bVisible)
	{
		if (!bVisible)
			DestroyVisualizations();
	}

	void DestroyVisualizations()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(DebugActor);
		if (Player != nullptr && bVisualizerCameraActive)
		{
			bVisualizerCameraActive = false;
			VisualizerCamera.DeactivateCamera(Player, 0.f);
			Player.ClearCameraSettingsByInstigator(this, 0.f);
		}

		if (bVisualizerMeshActive)
		{
			bVisualizerMeshActive = false;
			VisualizerMesh.SetActorHiddenInGame(true);

			if (VisualizerMeshComp != nullptr)
			{
				VisualizerMeshComp.SetHiddenInGame(false);
				VisualizerMeshComp = nullptr;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		// Update the zoom we have selected
		if (HasZoomRange())
		{
			if (ZoomRangeStart >= Component.Frames.Num() || ZoomRangeEnd >= Component.Frames.Num())
				ClearZoomRange();
		}

		// Play forward or backward depending on what the state is
		if (bPlayingRight && Component != nullptr && !Component.bEnabled)
		{
			PlayTime += DeltaTime;
			while (FrameIndex < Component.Frames.Num()-1 && PlayTime >= Component.Frames[FrameIndex+1].GameTime)
				SelectFrameByIndex(FrameIndex + 1);
		}
		else if (bPlayingLeft && Component != nullptr && !Component.bEnabled)
		{
			PlayTime -= DeltaTime;
			while (FrameIndex > 0 && PlayTime < Frame.GameTime)
				SelectFrameByIndex(FrameIndex - 1);
		}

		UpdateWatch(bPartialUpdate = true);
		UpdateSegmentColor(bPartialUpdate = true);

		bool bHaveCameraVisualization = false;
		FVector CameraVisLocation;
		FRotator CameraVisRotation;
		float CameraVisFOV = 70.f;

		bool bHaveAnimationVisualization = false;
		UAnimationAsset AnimVisAsset;
		float AnimVisPosition = 0.f;
		FVector AnimVisLocation;
		FRotator AnimVisRotation;
		FVector2D AnimVisBlendSpace;

		if (Frame != nullptr)
		{
			// Draw all the visualizations we want to see
			for (auto Obj : Frame.Objects)
			{
				for (auto& VisElem : Obj.Visualizations)
				{
					FName EntryName = VisElem.Key;
					bool bDrawIncluded = false;
					bool bDrawExcluded = false;

					for (FTemporalLogEntryRef& IncDraw : IncludedDraws)
					{
						if (IncDraw.ObjectName == Obj.ObjectName && IncDraw.ValueName == EntryName)
						{
							bDrawIncluded = true;
							break;
						}
					}

					for (FTemporalLogEntryRef& ExDraw : ExcludedDraws)
					{
						if (ExDraw.ObjectName == Obj.ObjectName && ExDraw.ValueName == EntryName)
						{
							bDrawExcluded = true;
							break;
						}
					}

					if (EntryName == WatchedValueName && Obj.ObjectName == WatchedObjectName)
					{
						bDrawIncluded = true;
						bDrawExcluded = false;
					}

					if (!bDrawExcluded)
					{
						for (auto& Vis : VisElem.Value.Visualizations)
						{
							if (Vis.bDrawByDefault || bDrawIncluded)
							{
								// Draw the debug lines for the visualization
								Vis.Draw();

								// Camera visualizations should override the player's camera to that position
								if (Vis.Type == ETemporalLogVisualizationType::Camera)
								{
									bHaveCameraVisualization = true;
									CameraVisLocation = Vis.Origin;
									CameraVisRotation = Vis.Rotation;
									CameraVisFOV = Vis.Target.X;
								}

								// Animation visualizations should override the player's mesh
								if (Vis.Type == ETemporalLogVisualizationType::Animation)
								{
									bHaveAnimationVisualization = true;
									AnimVisLocation = Vis.Origin;
									AnimVisRotation = Vis.Rotation;
									AnimVisAsset = Cast<UAnimationAsset>(Vis.Asset);
									AnimVisPosition = Vis.Target.X;
									AnimVisBlendSpace = FVector2D(Vis.Target.Y, Vis.Target.Z);
								}
							}

						}
					}
				}
			}
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(DebugActor);
		if (Player != nullptr)
		{
			if (bHaveCameraVisualization && Component != nullptr && !Component.bEnabled)
			{
				FHazeCameraBlendSettings Blend;
				Blend.BlendTime = 0.f;

				if (!bVisualizerCameraActive)
				{
					if (VisualizerCamera == nullptr)
						VisualizerCamera = AStaticCamera::Spawn();

					VisualizerCamera.ActivateCamera(Player, Blend);
					bVisualizerCameraActive = true;
				}

				VisualizerCamera.ActorLocation = CameraVisLocation;
				VisualizerCamera.ActorRotation = CameraVisRotation;

				FHazeCameraSettings CamSettings;
				CamSettings.bUseFOV = true;
				CamSettings.FOV = CameraVisFOV;
				Player.ApplySpecificCameraSettings(CamSettings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), Blend, Instigator = this);
			}
			else if (bVisualizerCameraActive)
			{
				bVisualizerCameraActive = false;
				VisualizerCamera.DeactivateCamera(Player, 0.f);
				Player.ClearCameraSettingsByInstigator(this, 0.f);
			}
		}

		if (bHaveAnimationVisualization && Component != nullptr && !Component.bEnabled)
		{
			if (!bVisualizerMeshActive)
			{
				if (VisualizerMesh == nullptr)
					VisualizerMesh = AHazeSkeletalMeshActor::Spawn();
				bVisualizerMeshActive = true;
			}

			auto VisComp = UHazeSkeletalMeshComponentBase::Get(DebugActor);
			if (VisComp != VisualizerMeshComp)
			{
				auto AnimInstClass = VisComp.AnimInstance.Class;
				VisualizerMesh.Mesh.SetAnimClass(AnimInstClass);
				VisualizerMesh.Mesh.SetSkeletalMesh(VisComp.SkeletalMesh);

				VisualizerMeshComp = VisComp;
				VisualizerMeshComp.SetHiddenInGame(true);
			}

			VisualizerMesh.SetActorHiddenInGame(false);

			UAnimSequence Sequence = Cast<UAnimSequence>(AnimVisAsset);
			if (Sequence != nullptr)
			{
				VisualizerMesh.StopBlendSpace();
				VisualizerMesh.PlaySlotAnimation(Animation = Sequence, StartTime = AnimVisPosition, PlayRate = 0.f, BlendTime = 0.f);
			}
			else
			{
				UBlendSpaceBase BlendSpace = Cast<UBlendSpaceBase>(AnimVisAsset);
				if (BlendSpace != nullptr)
				{
					VisualizerMesh.StopAllSlotAnimations();
					VisualizerMesh.SetBlendSpaceValues(AnimVisBlendSpace.X, AnimVisBlendSpace.Y, true);
					VisualizerMesh.PlayBlendSpace(BlendSpace, BlendTime = 0.f, PlayRate = 0.f, StartPosition = AnimVisPosition);
				}
			}

			VisualizerMesh.ActorLocation = AnimVisLocation;
			VisualizerMesh.ActorRotation = AnimVisRotation;
		}
		else if (bVisualizerMeshActive)
		{
			bVisualizerMeshActive = false;
			VisualizerMesh.SetActorHiddenInGame(true);

			if (VisualizerMeshComp != nullptr)
			{
				VisualizerMeshComp.SetHiddenInGame(false);
				VisualizerMeshComp = nullptr;
			}
		}

		if (PositionContext != 0 && Component != nullptr && !Component.bEnabled)
		{
			int FrameCount = Component.Frames.Num();
			int MinContext = FMath::Clamp(FrameIndex - PositionContext, 0, FrameCount - 1);
			FVector PreviousPosition = Frame.ActorLocation;

			float ColorStep = 1.f / float(PositionContext);
			float ColorAlpha = 0.f;
			for (int i = FrameIndex - 1; i >= MinContext && i < FrameCount; --i)
			{
				FVector NewPosition = Component.Frames[i].ActorLocation;

				FLinearColor PositionColor = FLinearColor::Blue * (1.f - ColorAlpha);
				PositionColor += FLinearColor::Red * ColorAlpha;
				ColorAlpha += ColorStep;

				System::DrawDebugPoint(NewPosition, 5.f, PositionColor, 0.f);
				System::DrawDebugLine(PreviousPosition, NewPosition, PositionColor, 0.f, 3.f);
				PreviousPosition = NewPosition;
			}

			int MaxContext = FMath::Clamp(FrameIndex + PositionContext, 0, Component.Frames.Num() - 1);

			PreviousPosition = Frame.ActorLocation;
			ColorStep = 1.f / float(PositionContext);
			ColorAlpha = 0.f;
			for (int i = FrameIndex + 1; i < MaxContext && i >= 0; ++i)
			{
				FLinearColor PositionColor = FLinearColor::Blue * (1.f - ColorAlpha);
				PositionColor += FLinearColor::Green * ColorAlpha;
				ColorAlpha += ColorStep;

				FVector NewPosition = Component.Frames[i].ActorLocation;
				System::DrawDebugPoint(Component.Frames[i].ActorLocation, 5.f, PositionColor, 0.f);
				System::DrawDebugLine(PreviousPosition, NewPosition, PositionColor, 0.f, 3.f);
				PreviousPosition = NewPosition;
			}
		}
	}

	UFUNCTION()
	void StartPlaying(bool bReverse)
	{
		if (Frame == nullptr)
			return;
		bPlayingLeft = bReverse;
		bPlayingRight = !bReverse;
		PlayTime = Frame.GameTime;
	}

	UFUNCTION()
	void StopPlaying()
	{
		bPlayingLeft = false;
		bPlayingRight = false;
	}

	UFUNCTION()
	void SetZoomRange(int StartFrame, int EndFrame)
	{
		ZoomRangeStart = StartFrame;
		ZoomRangeEnd = EndFrame;
		UpdateFrame();
	}

	UFUNCTION()
	void ClearZoomRange()
	{
		ZoomRangeStart = -1;
		ZoomRangeEnd = -1;
		UpdateFrame();
	}

	UFUNCTION(BlueprintPure)
	bool HasZoomRange() const
	{
		return ZoomRangeStart != -1 && ZoomRangeEnd != -1;
	}
};