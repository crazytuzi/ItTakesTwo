
enum ENetworkProfilerSpanType
{
	PrevSecond,
	PeakSecond,
	PeakMinute,
	TotalSession,
};

enum ENetworkProfilerViewType
{
	ByMessageType,
	ByMessageSegment,
	ByRPCFunction,
	ByChannel,
};

const FHazeNetworkProfilerSpan EmptySpan;
const TMap<FName, FHazeNetworkProfilerStat> EmptyStatView;

class UNetworkProfilerWidget : UHazeUserWidget
{
	UPROPERTY()
	UHazeNetworkProfilerSession Session;

	UPROPERTY()
	ENetworkProfilerSpanType SpanType = ENetworkProfilerSpanType::PrevSecond;

	UPROPERTY()
	ENetworkProfilerViewType ViewType = ENetworkProfilerViewType::ByRPCFunction;

	UPROPERTY()
	TSubclassOf<UNetworkProfilerStatWidget> StatWidgetClass;

	TArray<UNetworkProfilerStatWidget> StatLines;

	UPROPERTY()
	TArray<UHazeDevButton> SpanTypeButtons;

	UPROPERTY()
	TArray<UHazeDevButton> ViewTypeButtons;

	UFUNCTION(BlueprintEvent)
	UPanelWidget GetStatListWidget()
	{
		return nullptr;
	}

	UFUNCTION()
	void SelectSpanType(UHazeDevButton SpanTypeButton)
	{
		for (int i = 0, Count = SpanTypeButtons.Num(); i < Count; ++i)
		{
			bool bActive = (SpanTypeButtons[i] == SpanTypeButton);
			SpanTypeButtons[i].SetActivated(bActive);
			if (bActive)
				SpanType = ENetworkProfilerSpanType(i);
		}
		UpdateSpan();
	}

	UFUNCTION()
	void SelectViewType(UHazeDevButton ViewTypeButton)
	{
		for (int i = 0, Count = ViewTypeButtons.Num(); i < Count; ++i)
		{
			bool bActive = (ViewTypeButtons[i] == ViewTypeButton);
			ViewTypeButtons[i].SetActivated(bActive);
			if (bActive)
				ViewType = ENetworkProfilerViewType(i);
		}
		UpdateStatView();
	}

	UFUNCTION()
	void UpdateSession()
	{
		UpdateSpan();
	}

	UFUNCTION()
	void UpdateSpan()
	{
		UpdateStatView();
	}

	UFUNCTION()
	void UpdateStatView()
	{
		const auto& Stats = GetStatView();

		int OldCount = StatLines.Num();
		int NewCount = Stats.Num();

		// Remove old widgets
		for (int i = NewCount; i < OldCount; ++i)
			StatLines[i].RemoveFromParent();

		StatLines.SetNum(NewCount);

		// Add new widgets
		auto StatList = GetStatListWidget();
		for (int i = OldCount; i < NewCount; ++i)
		{
			auto Widget = Cast<UNetworkProfilerStatWidget>(Widget::CreateWidget(this, StatWidgetClass.Get()));
			StatLines[i] = Widget;

			if (StatList != nullptr)
				StatList.AddChild(Widget);
		}

		// Update widget data
		int WidgetIndex = 0;
		float Duration = GetSpan().Duration;
		for (auto& Elem : Stats)
		{
			auto Widget = StatLines[WidgetIndex++];
			Widget.SetStat(Elem.Key, Elem.Value, Duration);
		}
	}

	UFUNCTION()
	void UpdateText(UTextBlock IncomingText, UTextBlock OutgoingText, UTextBlock StatViewText)
	{
		if (Session == nullptr)
			return;
		if (Session.PrevSecond.Duration <= 0.f)
			return;
 
		float CurIncomingKbps = float(Session.PrevSecond.Total.ReceivedBits) / Session.PrevSecond.Duration / 1024.f;
		IncomingText.SetText(FText::FromString("Incoming: "+TrimFloatValue(CurIncomingKbps)+" kbps"));

		float CurOutgoingKbps = float(Session.PrevSecond.Total.SentBits) / Session.PrevSecond.Duration / 1024.f;
		OutgoingText.SetText(FText::FromString("Outgoing: "+TrimFloatValue(CurOutgoingKbps)+" kbps"));

		const auto& CurSpan = GetSpan();
		if (CurSpan.Duration > 0.f)
		{
			StatViewText.SetText(FText::FromString(
				"Sent "
				+TrimFloatValue(float(CurSpan.Total.SentBits) / CurSpan.Duration / 1024.f)
				+"kbps, Received "
				+TrimFloatValue(float(CurSpan.Total.ReceivedBits) / CurSpan.Duration / 1024.f)
				+"kbps over "+TrimFloatValue(CurSpan.Duration)+" seconds"));
		}
		else
		{
			StatViewText.SetText(FText::FromString(""));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		UpdateStatView();
	}

	const FHazeNetworkProfilerSpan& GetSpan()
	{
		if (Session != nullptr)
		{
			switch(SpanType)
			{
				case ENetworkProfilerSpanType::PrevSecond:
					return Session.PrevSecond;
				case ENetworkProfilerSpanType::PeakSecond:
					return Session.PeakSecond;
				case ENetworkProfilerSpanType::PeakMinute:
					return Session.PeakMinute;
				case ENetworkProfilerSpanType::TotalSession:
					return Session.TotalSession;
			}
		}

		return EmptySpan;
	}

	const TMap<FName, FHazeNetworkProfilerStat>& GetStatView()
	{
		const FHazeNetworkProfilerSpan& CurSpan = GetSpan();
		switch (ViewType)
		{
			case ENetworkProfilerViewType::ByChannel:
				return CurSpan.ByChannel;
			case ENetworkProfilerViewType::ByMessageType:
				return CurSpan.ByMessageType;
			case ENetworkProfilerViewType::ByRPCFunction:
				return CurSpan.ByRPCFunction;
			case ENetworkProfilerViewType::ByMessageSegment:
				return CurSpan.ByMessageSegment;
		}

		return EmptyStatView;
	}
};

class UNetworkProfilerStatWidget : UHazeUserWidget
{
	UPROPERTY()
	FName StatName;

	UPROPERTY()
	float IncomingKbps;

	UPROPERTY()
	int IncomingCount;

	UPROPERTY()
	float OutgoingKbps;

	UPROPERTY()
	int OutgoingCount;

	UPROPERTY()
	float SampleDuration;

	void SetStat(FName NewName, const FHazeNetworkProfilerStat& Stat, float Duration)
	{
		if (Duration <= 0.f)
			return;

		float NewIncoming = float(Stat.ReceivedBits) / 1024.f;
		float NewOutgoing = float(Stat.SentBits) / 1024.f;

		if(Duration >= 2.f)
		{
			NewIncoming /= Duration;
			NewOutgoing /= Duration;
		}

		bool bMadeChange = StatName != NewName || !FMath::IsNearlyEqual(NewIncoming, IncomingKbps) || !FMath::IsNearlyEqual(NewOutgoing, OutgoingKbps);
		if (bMadeChange)
		{
			IncomingKbps = NewIncoming;
			OutgoingKbps = NewOutgoing;
			IncomingCount = Stat.ReceivedMessageCount;
			OutgoingCount = Stat.SentMessageCount;
			SampleDuration = Duration;
			StatName = NewName;
			Update();
		}
	}

	UFUNCTION(BlueprintEvent)
	void Update() {}

	UFUNCTION()
	void UpdateText(UTextBlock NameText, UTextBlock IncomingText, UTextBlock OutgoingText)
	{
		NameText.SetText(FText::FromString(StatName.ToString()));

		FString IncomingStr = TrimFloatValue(IncomingKbps);
		FString OutgoingStr = TrimFloatValue(OutgoingKbps);

		if (SampleDuration < 2.f)
		{
			IncomingStr += " kb ("+IncomingCount+"x)";
			OutgoingStr += " kb ("+OutgoingCount+"x)";
		}
		else
		{
			IncomingStr += " kbps";
			OutgoingStr += " kbps";
		}

		IncomingText.SetText(FText::FromString(IncomingStr));
		OutgoingText.SetText(FText::FromString(OutgoingStr));
	}
};

class UNetworkProfilerGraphWidget : UHazeUserWidget
{
	UPROPERTY()
	UNetworkProfilerWidget Profiler;

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		if (Profiler == nullptr)
			return;
		if (Profiler.Session == nullptr)
			return;

		TArray<FVector2D> OutgoingLines;
		TArray<FVector2D> IncomingLines;

		FGeometry Geometry = GetCachedGeometry();

		int StartIndex = FMath::Max(0, Profiler.Session.SecondTotals.Num() - 60);
		int PointCount = FMath::Min(60, Profiler.Session.SecondTotals.Num());

		OutgoingLines.SetNum(PointCount * 2);
		IncomingLines.SetNum(PointCount * 2);

		float Time = 0.f;

		float Budget = Network::GetMaximumTrafficBudget();
		float MaxYValue = Budget;

		FVector2D PrevIncoming;
		FVector2D PrevOutgoing;

		for(int i = 0; i < PointCount; ++i)
		{
			const FHazeNetworkProfilerTotals& Second = Profiler.Session.SecondTotals[i + StartIndex];

			FVector2D CurIncoming;
			CurIncoming.X = Time;
			CurIncoming.Y = float(Second.Total.ReceivedBits) / Second.Duration / 1024.f;

			FVector2D CurOutgoing;
			CurOutgoing.X = Time;
			CurOutgoing.Y = float(Second.Total.SentBits) / Second.Duration / 1024.f;

			if (CurIncoming.Y > MaxYValue)
				MaxYValue = CurIncoming.Y;
			if (CurOutgoing.Y > MaxYValue)
				MaxYValue = CurOutgoing.Y;

			Time += Second.Duration;

			// Add line the drawlist
			if(i == 0)
			{
				OutgoingLines[i*2] = CurOutgoing;
				IncomingLines[i*2] = CurIncoming;
			}
			else
			{
				OutgoingLines[i*2] = PrevOutgoing;
				IncomingLines[i*2] = PrevIncoming;
			}

			OutgoingLines[i*2 + 1] = CurOutgoing;
			IncomingLines[i*2 + 1] = CurIncoming;

			PrevOutgoing = CurOutgoing;
			PrevIncoming = CurIncoming;
		}

		// Scale the position of the lines with the size of the graph
		float XScale = Geometry.LocalSize.X / FMath::Max(Time, 60.f);
		float YScale = Geometry.LocalSize.Y / MaxYValue * -1.f;
		float YOffset = Geometry.LocalSize.Y;
		for (int i = 0; i < PointCount * 2; ++i)
		{
			OutgoingLines[i].X = FMath::RoundToInt(OutgoingLines[i].X * XScale);
			IncomingLines[i].X = FMath::RoundToInt(IncomingLines[i].X * XScale);
			OutgoingLines[i].Y = YOffset + FMath::RoundToInt(OutgoingLines[i].Y * YScale);
			IncomingLines[i].Y = YOffset + FMath::RoundToInt(IncomingLines[i].Y * YScale);
		}

		WidgetBlueprint::DrawLines(Context, IncomingLines, FLinearColor::Blue, false, 1.f);
		WidgetBlueprint::DrawLines(Context, OutgoingLines, FLinearColor::Green, false, 1.f);

		WidgetBlueprint::DrawLine(
			Context,
			FVector2D(0.f, YOffset + YScale * Budget),
			FVector2D(Geometry.LocalSize.X, YOffset + YScale * Budget),
			FLinearColor::Red, false, 1.f
		);
	}
};