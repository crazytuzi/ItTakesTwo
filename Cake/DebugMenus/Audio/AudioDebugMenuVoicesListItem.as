
class UAudioDebugMenuVoicesListItem : UHazeUserWidget
{
	FWaapiVoiceData Data;

	UFUNCTION(BlueprintCallable)
	FWaapiVoiceData GetVoiceData() property
	{
		return Data;
	}

	void SetVoiceData(FWaapiVoiceData Data) property
	{
		this.Data = Data;
	}

	void SetGameObjectData(UHazeAkComponent GameObject) property
	{
		Data.Component = GameObject;
		Data.bIsVirtual = GameObject.ActiveEventInstances.Num() == 0;
		Data.bIsForcedVirtual = false;
		Data.GameObjectName = GameObject.GetName();
		Data.ObjectName = "This is only from game data...";
	}

	UFUNCTION()
	void SetColorBasedOnData(UTextBlock Text) 
	{
		FSlateColor Color;
		Color.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;

		if (VoiceData.bIsVirtual) 
		{
			Color.SpecifiedColor = FLinearColor::Gray;
		}
		else if (VoiceData.bIsForcedVirtual) 
		{
			Color.SpecifiedColor = FLinearColor::Gray;
		}
		else {
			Color.SpecifiedColor = FLinearColor::Green;
		}

		Text.SetColorAndOpacity(Color);
	}


	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
	}
	
	UFUNCTION(BlueprintEvent)
	UTextBlock GetGameObjectName() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetObjectName() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UCheckBox GetIsForcedVirtual() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UCheckBox GetIsVirtual() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UCheckBox GetIsStarted() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UListView GetActiveEvents() property
	{
		return nullptr;
	}

}