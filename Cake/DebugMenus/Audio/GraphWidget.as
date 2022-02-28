
struct FGraphTimelineData 
{
	float Value;
	float Duration;
};

USTRUCT()
struct FGraphSettings
{
	//Will change depending on added values
	UPROPERTY()
	float DefaultMaxYValue = 1;
	//Will change depending on added values
	UPROPERTY()
	float DefaultMinYValue = -1;

	int FramesToShow = 60 * 30;
	FString MinText = "Min Value: ";
	FString MaxText = "Max Value: ";
};

class FGraphEntryData
{
	FString Id;
	FLinearColor Color;
	TArray<FVector2D> Line;
	TArray<FGraphTimelineData> Elements;
	// //This is a minor optimization, must be updated when removing/changing entries.
	// float TotalDuration;
	float HoveredValue;

	float MaxYValue;
	float MinYValue;
};

class UGraphWidget : UHazeUserWidget
{
	UPROPERTY()
	UPanelWidget OriginalParent;

	float MaxYValue = 100;
	float MinYValue = 0;
	int CurrentLinePosition;

	UPROPERTY()
	FGraphSettings Settings;

	float FontSize;
	UFont TextFont;
	FText MaxValueText;
	FText MinValueText;

	TMap<FString, FGraphEntryData> MappedEntries;
	TSet<FLinearColor> UniqueColors;

	UFUNCTION(BlueprintEvent)
	UTextBlock GetFloatText() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Construct() 
	{
		if (TextFont == nullptr)
		{
			TextFont = GetFontForText();
		}

		CurrentLinePosition = Settings.FramesToShow;
		MaxYValue = Settings.DefaultMaxYValue;
		MinYValue = Settings.DefaultMinYValue;
		MaxValueText = FText::FromString(Settings.MaxText + MaxYValue);
		MinValueText = FText::FromString(Settings.MinText + MinYValue);
		FontSize = 12;
	}

	UFont GetFontForText()
	{
		FSlateFontInfo FontInfo = FloatText.GetFont();

		return Cast<UFont>(FontInfo.FontObject);
	}

	FLinearColor GetUniqueColor() 
	{
		auto NewColor = FLinearColor::MakeRandomColor();
		while (UniqueColors.Contains(NewColor))
		{
			NewColor = FLinearColor::MakeRandomColor();
		}

		UniqueColors.Add(NewColor);
		return NewColor;
	}

	bool Add(FString Id, FLinearColor& AssignedColor)
	{
		FGraphEntryData Entry;
		if (!MappedEntries.Find(Id, Entry))
		{
			Entry = FGraphEntryData();
			Entry.Id = Id;
			Entry.Color = GetUniqueColor();
			MappedEntries.Add(Id, Entry);

			AssignedColor = Entry.Color;
			return true;
		}

		return false;
	}

	FGraphTimelineData TempCopy;
	void AddElement(FString Id, float Value)
	{
		TempCopy.Value = Value;
		AddElement(Id, TempCopy);
	}

	void AddElement(FString Id, const FGraphTimelineData Element)
	{
		FGraphEntryData Entry;
		if (MappedEntries.Find(Id, Entry))
		{
			//Change with multiplier so it doesn't change to often.
			if (Element.Value > Entry.MaxYValue) 
			{
				Entry.MaxYValue = FMath::Abs(Element.Value * 2);
				// MaxValueText = FText::FromString(Settings.MaxText + MaxYValue);
			}
			if (Element.Value < Entry.MinYValue) 
			{
				Entry.MinYValue = -FMath::Abs(Element.Value * 2);
				// MinValueText = FText::FromString(Settings.MinText + MinYValue);
			}

			// No need to cache to many values.
			if (Entry.Elements.Num() >= Settings.FramesToShow) 
			{
				const auto OldElement = Entry.Elements[0];
				Entry.Elements.RemoveAt(0);

				// Entry.TotalDuration -= OldElement.Duration;
			}
		}
		else 
		{
			Entry = FGraphEntryData();
			Entry.Id = Id;
			Entry.Color = GetUniqueColor();
			Entry.MaxYValue = FMath::Max(0.f, Element.Value);
			Entry.MinYValue = FMath::Min(0.f, Element.Value);
			MappedEntries.Add(Id, Entry);
		}

		Entry.Elements.Add(Element);
		// Entry.TotalDuration += Element.Duration;
	}

	bool Remove(FString Id) 
	{
		FGraphEntryData Entry;
		if (MappedEntries.Find(Id, Entry))
		{
			UniqueColors.Remove(Entry.Color);
			return MappedEntries.Remove(Id);
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry Geometry, FPointerEvent MouseEvent)
	{
		UpdateHovered(Geometry, MouseEvent);
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		CurrentLinePosition = Settings.FramesToShow;
	}

	void UpdateHovered(FGeometry Geometry, FPointerEvent MouseEvent)
	{
		FVector2D ScreenPos = Input::PointerEvent_GetScreenSpacePosition(MouseEvent);
		FVector2D LocalPos = Geometry.AbsoluteToLocal(ScreenPos);

		CurrentLinePosition = LocalPos.X;
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		FGeometry Geometry = GetCachedGeometry();
		
		float TextPercentage = 0.05f;
		float YReservedTextSpace = (Geometry.LocalSize.Y * TextPercentage) * (MappedEntries.Num() + 1);
		// Scale the position of the lines with the size of the graph
		float XScale = Geometry.LocalSize.X / Settings.FramesToShow;
		float YOffset = Geometry.LocalSize.Y - YReservedTextSpace;

		for (auto& Pair: MappedEntries)
		{
			FGraphEntryData& Entry = Pair.Value;
			TArray<FVector2D>& Line = Entry.Line;

			if (Entry.Elements.Num() == 0) 
			{
				continue;
			}

			// float YScale = Geometry.LocalSize.Y / Entry.MaxYValue * -1.f;
			int StartIndex = FMath::Max(0,  Entry.Elements.Num() - Settings.FramesToShow);
			int PointCount = FMath::Min(Settings.FramesToShow, Entry.Elements.Num());
			float XOffset = Settings.FramesToShow - Entry.Elements.Num();

			Line.SetNum(PointCount * 2);
			float NewTime = SetLineEntries(
				PointCount, StartIndex, 
				Entry.Elements, Line, Entry.HoveredValue,
				XScale, Entry.MaxYValue, Entry.MinYValue, 
				XOffset, YOffset);
		}

		float LinePositionX = CurrentLinePosition == Settings.FramesToShow ?  Geometry.LocalSize.X : CurrentLinePosition;
		float Counter = 1;

		// const FString MutableMinValueText;
		// const FString MutableMaxValueText;
		for (auto& Pair: MappedEntries)
		{
			FGraphEntryData& Entry = Pair.Value;
			TArray<FVector2D>& Line = Entry.Line;

			if (Entry.Elements.Num() == 0) 
			{
				continue;
			}
			
			// if (CurrentLinePosition != Settings.FramesToShow)
			// {
				
				const FString KeyValue = Entry.Id + 
					", Max: " + Entry.MaxYValue + 
					", Min: " + Entry.MinYValue + 
					", Current: " + Entry.HoveredValue;
				const FText Text = FText::FromString(KeyValue);
				
				float ApproxWidth = KeyValue.Len() * 17.5 * XScale;
				// FVector2D TextPosition = 
				// 	FVector2D(LinePositionX, 
				// 	FMath::RoundToInt(Math::GetPercentageBetween(MaxYValue, MinYValue, Entry.HoveredValue) * YOffset)
				// 	);
				FVector2D TextPosition = 
					FVector2D(ApproxWidth, YOffset + Counter * (Geometry.LocalSize.Y * TextPercentage));
				TextPosition.X -= ApproxWidth;
				WidgetBlueprint::DrawTextFormatted(Context, Text, TextPosition, TextFont, FontSize, Tint = Entry.Color);
				++Counter;
			// }
			
			WidgetBlueprint::DrawLines(Context, Line, Entry.Color, false, 1.f);
		}

		// //Min
		// WidgetBlueprint::DrawTextFormatted(
		// 	Context, 
		// 	MinValueText, 
		// 	FVector2D(0.f, YOffset - 12), 
		// 	TextFont, 
		// 	FontSize
		// 	);

		// //Max
		// WidgetBlueprint::DrawTextFormatted(
		// 	Context, 
		// 	MaxValueText, 
		// 	FVector2D(0.f, 0.f), 
		// 	TextFont, 
		// 	FontSize
		// 	);

		// Line to show most recent value
		WidgetBlueprint::DrawLine(
			Context,
			FVector2D(LinePositionX, 0.f),
			FVector2D(LinePositionX, YOffset),
			FLinearColor::Yellow, false, 1.f
		);
	}

	float SetLineEntries(int PointCount, int StartIndex, 
		TArray<FGraphTimelineData>& Elements, TArray<FVector2D>& Line, float& HoveredValue,
		float XScale, float MaxY, float MinY, float XOffset, float YOffset) const
	{
		FVector2D Previous;
		float NewTime = 0;
		float LinePositionX = CurrentLinePosition == Settings.FramesToShow ? Settings.FramesToShow - XOffset : CurrentLinePosition;
		bool bFoundHoveredValue = false;

		for(int i = 0; i < PointCount; ++i)
		{
			const FGraphTimelineData& Data = Elements[i + StartIndex];

			FVector2D Current;
			Current.X = FMath::RoundToInt(((XOffset + i) * XScale));
			if (Current.X == LinePositionX) 
			{
				bFoundHoveredValue = true;
				HoveredValue = Data.Value;
			}

			Current.Y = FMath::RoundToInt(Math::GetPercentageBetween(MaxY, MinY, Data.Value) * YOffset);
			
			NewTime += Data.Duration;

			// Add line the drawlist
			if(i == 0)
			{
				Line[i*2] = Current;
			}
			else
			{
				Line[i*2] = Previous;
			}

			Line[i*2 + 1] = Current;

			Previous = Current;
		}

		if (!bFoundHoveredValue)
		{
			HoveredValue = Elements.Last().Value;
		}

		return NewTime;
	}
};