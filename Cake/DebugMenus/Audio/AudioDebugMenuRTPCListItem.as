event void FOnAddRTPC(UAudioDebugMenuRTPCListItem Item);
event void FOnRemoveRTPC(UAudioDebugMenuRTPCListItem Item);

struct FAudioRTPCItemData
{
	FName RTPCName;
	ERTPCValueType RTPCType;
	// Needed for object rtpcs
	AActor Actor;
	// Needed for object rtpcs
	int PlayingId;

	FLinearColor Color;
}

class UAudioDebugMenuRTPCListItem : UHazeUserWidget
{
	FAudioRTPCItemData ElementData;
	bool IsStatic = false;

	FOnAddRTPC AddEvent;
	FOnAddRTPC RemoveEvent;

	void Setup(UHazeUserWidget ParentWidget, FName RTPCName, FLinearColor Color, bool bIsStatic = false) 
	{
		AddEvent.AddUFunction(ParentWidget, n"OnAddRTPC");
		RemoveEvent.AddUFunction(ParentWidget, n"OnRemoveRTPC");

		ElementData.RTPCName = RTPCName;
		ElementData.Color = Color;
		SetGlobal();

		ESlateVisibility StaticValue = bIsStatic ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		ESlateVisibility NotStaticValue = bIsStatic ? ESlateVisibility::Collapsed : ESlateVisibility::Visible;

		AddButton.SetVisibility(StaticValue);
		RemoveButton.SetVisibility(NotStaticValue);

		EditableText.SetVisibility(StaticValue);
		Text.SetVisibility(NotStaticValue);
		ValueText.SetVisibility(NotStaticValue);

		if (!bIsStatic)
			SetupTexts(Text, ValueText);
		
		IsStatic = bIsStatic;
	}

	UFUNCTION()
	void SetupTexts(UTextBlock TextBlock, UTextBlock ValueTextBlock)
	{
		TextBlock.SetText(FText::FromName(ElementData.RTPCName));

		FSlateColor SlateColor;
		SlateColor.SpecifiedColor = ElementData.Color;
		SlateColor.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		TextBlock.SetColorAndOpacity(SlateColor);
		ValueTextBlock.SetColorAndOpacity(SlateColor);
	}

	void UpdateRTPC(float NewValue) 
	{
		if (ValueText != nullptr)
			ValueText.SetText(FText::FromString(": "+NewValue));
	}

	UFUNCTION(BlueprintEvent)
	void OnForceSelectionChange(FString RtpcType, FString Actor) 
	{
	}

	UFUNCTION(BlueprintEvent)
	UEditableText GetEditableText() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetText() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetValueText() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UButton GetAddButton() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UButton GetRemoveButton() property
	{
		return nullptr;
	}

	UFUNCTION()
	void SetActor(AActor Actor)
	{
		ElementData.Actor = Actor;
		ElementData.PlayingId = 0;
		ElementData.RTPCType = ERTPCValueType::GameObject;
	}

	UFUNCTION()
	void SetPlayingId(int PlayingId)
	{
		ElementData.Actor = nullptr;
		ElementData.PlayingId = PlayingId;
		ElementData.RTPCType = ERTPCValueType::PlayingID;
	}

	UFUNCTION()
	void SetGlobal()
	{
		ElementData.Actor = nullptr;
		ElementData.PlayingId = 0;
		ElementData.RTPCType = ERTPCValueType::Global;
	}

	UFUNCTION()
	void AddRtpc()
	{
		AddEvent.Broadcast(this);
	}

	UFUNCTION()
	void RemoveRtpc()
	{
		RemoveEvent.Broadcast(this);
	}
}