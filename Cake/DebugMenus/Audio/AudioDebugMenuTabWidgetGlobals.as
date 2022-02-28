import Cake.DebugMenus.Audio.AudioDebugMenuTabWidget;
import Cake.DebugMenus.Audio.AudioDebugMenuVoicesListItem;
import Cake.DebugMenus.Audio.AudioDebugMenuEventInstanceListItem;

class UAudioDebugMenuTabWidgetGlobals : UAudioDebugMenuTabWidget
{
	UFUNCTION(BlueprintEvent)
	UListView GetGameObjectWidgets() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UListView GetEventWidgets() property
	{
		return nullptr;
	}

	void UpdateVoices(TArray<FWaapiVoiceData> Voices) 
	{
		// Q: Add pooling?

		GameObjectWidgets.ClearListItems();
		EventWidgets.ClearListItems();

		for	(auto VoiceData : Voices)
		{
			auto GameObjectItem = Cast<UAudioDebugMenuVoicesListItem>(
				Widget::CreateWidget(this, GameObjectWidgets.EntryWidgetClass)
				);	
			GameObjectItem.SetVoiceData(VoiceData);
			GameObjectWidgets.AddItem(GameObjectItem);

			if (VoiceData.Component != nullptr) 
			{
				auto ActiveEvents = VoiceData.Component.ActiveEventInstances;
				for (auto EventInstance : ActiveEvents) 
				{
					auto EventItem = Cast<UAudioDebugMenuEventInstanceListItem>(
						Widget::CreateWidget(this, EventWidgets.EntryWidgetClass)
						);

					EventItem.SetItemData(EventInstance);
					EventWidgets.AddItem(EventItem);
				}

			}	
		}	
	}

	void UpdateGameObjects() 
	{
		TArray<UAkComponent> Components = Audio::GetAllAkComponents();

		GameObjectWidgets.ClearListItems();
		EventWidgets.ClearListItems();

		for	(auto Component : Components)
		{
			if (Component == nullptr)
				continue;

			auto HazeComponent = Cast<UHazeAkComponent>(Component);
			if (HazeComponent == nullptr)
				continue;

			auto GameObjectItem = Cast<UAudioDebugMenuVoicesListItem>(
				Widget::CreateWidget(this, GameObjectWidgets.EntryWidgetClass)
				);	
			
			GameObjectItem.SetGameObjectData(HazeComponent);
			GameObjectWidgets.AddItem(GameObjectItem);

			for (auto EventInstance : HazeComponent.ActiveEventInstances) 
			{
				auto EventItem = Cast<UAudioDebugMenuEventInstanceListItem>(
					Widget::CreateWidget(this, EventWidgets.EntryWidgetClass)
					);

				EventItem.SetItemData(EventInstance);
				EventWidgets.AddItem(EventItem);
			}
		}
	}


	UFUNCTION(BlueprintCallable)
	void SetEventDetails(UTextBlock TextBlock, FHazeAudioEventInstance EventInstance) 
	{
		FString Text;
		Text += "EventName: " + EventInstance.EventName;
		Text += "\n PlayingID: " + EventInstance.PlayingID;
		Text += "\n MaxAttenuation: " + EventInstance.MaxAttenuation;
		Text += "\n bStopOnDisable: " + EventInstance.bStopOnDisable;
		Text += "\n MinDuration: " + EventInstance.MinDuration;
		Text += "\n MaxDuration: " + EventInstance.MaxDuration;
		Text += "\n bActive: " + EventInstance.bActive;
		Text += "\n EventTag: " + EventInstance.EventTag;

		TextBlock.SetText(FText::FromString(Text));
	}

	
	UFUNCTION(BlueprintCallable)
	void SetGameObjectDetails(UTextBlock TextBlock, FWaapiVoiceData VoiceData) 
	{
		FString Text;
		Text += "GameObjectName: " + VoiceData.GameObjectName;
		Text += "\n ObjectName: " + VoiceData.ObjectName;
		Text += "\n bIsStarted: " + VoiceData.bIsStarted;
		Text += "\n bIsVirtual: " + VoiceData.bIsVirtual;
		Text += "\n bIsForcedVirtual: " + VoiceData.bIsForcedVirtual;

		TextBlock.SetText(FText::FromString(Text));
	}

}