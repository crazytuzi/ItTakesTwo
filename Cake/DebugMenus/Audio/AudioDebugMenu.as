import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.AudioSpline.AudioSpline;
import Peanuts.Audio.AmbientZone.AmbientZone;
import Cake.DebugMenus.Audio.AudioDebugMenuTabWidget;
import Cake.DebugMenus.Audio.AudioDebugMenuTabWidgetGlobals;
import Cake.DebugMenus.Audio.AudioDebugMenuTabWidgetVisualizations;
import Cake.DebugMenus.Audio.AudioDebugViewportWidget;
import Cake.DebugMenus.Audio.AudioDebugMenuRTPCWidget;
import Cake.DebugMenus.Audio.AudioDebugMenuButton;

#if TEST
import void RegisterDebugMenu(UAudioDebugMenu) from "Cake.DebugMenus.Audio.AudioDebugManager";
import void UnregisterDebugMenu(UAudioDebugMenu) from "Cake.DebugMenus.Audio.AudioDebugManager";
#endif

class UAudioDebugMenu : UHazeDebugMenuScriptBase
{
	const float TickGroupVisualizer = 5.f;
	const float TickGroupWAAPI = 2.f;
	float VisualizerTimer = 1.f;
	float WAAPITimer = 5.f;

	UPROPERTY(EditInstanceOnly, meta = "How often should the RTPC lookup be done, zero equals to every frame")
	float RTPCCheckFrequency = 0.f;
	float RTPCTimer = 0.f;

	bool bSubscriptionDone = false;
	EAudioDebugMode SelectedDebugMode = EAudioDebugMode::None;
	bool bViewportsEnabled = true;

	EBankLoadState BankLoadStateToShow = EBankLoadState::BankLoaded_UnloadRequested;

	UPROPERTY(Transient)
	UHazeTextWigdet ActiveVoices;

	UPROPERTY()
	TSubclassOf<UAudioDebugViewportWidget> ViewportWidget;
	UAudioDebugViewportWidget MaysViewport;
	UAudioDebugViewportWidget CodysViewport;

	UPROPERTY()
	TSubclassOf<UAudioDebugMenuRTPCWidget> RtpcWidgetClass;
	UAudioDebugMenuRTPCWidget RtpcWidget;
	UAudioDebugMenuRTPCWidget ProfilerWidget;

	UPROPERTY()
	TSubclassOf<UAudioDebugMenuButton> DebugButtonClass;
	TMap<EAudioDebugMode, UAudioDebugMenuButton> DebugButtons;

	UFUNCTION(BlueprintEvent)
	UWidgetSwitcher GetTabSwitcher() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UVerticalBox GetButtonVerticalBox() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UHazeTextWigdet GetDebugText() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetSelectedDebugText() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UEditableText GetActiveSoundsFilter() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UComboBoxString GetBankStateDropdown() property
	{
		return nullptr;
	}

	UFUNCTION()
	void OnConstruct()
	{
		#if TEST
		RegisterDebugMenu(this);
		#endif

		#if EDITOR
		SelectedDebugMode = EAudioDebugMode::General;
		#endif

		MaysViewport = Cast<UAudioDebugViewportWidget>(Widget::CreateWidget(this, ViewportWidget));
		CodysViewport = Cast<UAudioDebugViewportWidget>(Widget::CreateWidget(this, ViewportWidget));

		MaysViewport.Setup(true);
		CodysViewport.Setup(false);

		RtpcWidget = Cast<UAudioDebugMenuRTPCWidget>(
			Widget::CreateWidget(this, RtpcWidgetClass));
		RtpcWidget.Setup(MaysViewport, true);

		ProfilerWidget = Cast<UAudioDebugMenuRTPCWidget>(
			Widget::CreateWidget(this, RtpcWidgetClass));
		ProfilerWidget.Setup(MaysViewport, false);

		ActivateViewports(false);
		bViewportsEnabled = false;

		ActivateRTPCWidget(false);
		ActivateProfilerWidget(false);

		SetupDebugButtons();

		for (int i = 1; i < int(EBankLoadState::EBankLoadState_MAX); ++i)
		{
			BankStateDropdown.AddOption((""+ EBankLoadState(i)).Replace("EBankLoadState::", ""));
		}
		BankStateDropdown.SetSelectedIndex(int(EBankLoadState::BankLoaded_UnloadRequested -1));
		BankStateDropdown.OnSelectionChanged.AddUFunction(this, n"OnBankStateSelectionChange");
	}

	UFUNCTION()
	void OnBankStateSelectionChange(FString SelectedItem, ESelectInfo SelectionType)
	{	
		BankLoadStateToShow = EBankLoadState(BankStateDropdown.SelectedIndex + 1);
	}

	void SetupDebugButtons()
	{
		for(int i=0; i < int(EAudioDebugMode::NumOfModes); ++i)
		{
			auto NewButton = Cast<UAudioDebugMenuButton>(Widget::CreateWidget(ButtonVerticalBox, DebugButtonClass));
			if (NewButton == nullptr)
				continue;

			NewButton.DebugMode = EAudioDebugMode(i);
			NewButton.Text.SetText(FText::FromString(HazeAudio::ToString(NewButton.DebugMode)));

			FDebugButtonClicked ClickedEvent;
			ClickedEvent.AddUFunction(this, n"ActivateDebugMode");
			NewButton.Setup(ClickedEvent);

			#if TEST
			NewButton.SetDebugEnabled(HazeAudio::IsDebugEnabled(NewButton.DebugMode));
			#else
			NewButton.SetDebugEnabled(false);
			#endif

			DebugButtons.Add(NewButton.DebugMode,  NewButton);
			ButtonVerticalBox.AddChild(NewButton);
		}
	}

	UFUNCTION()
	void OnDestruct()
	{
		#if TEST
		UnregisterDebugMenu(this);
		#endif
	}

	UFUNCTION()
	void ActivateDebugMode(UAudioDebugMenuButton Button)
	{
		Button.SetDebugEnabled(!Button.IsDebugEnabled());
		
		int Value = Button.IsDebugEnabled() ? 1 : 0;
		Console::SetConsoleVariableInt(HazeAudio::ToCVARString(Button.DebugMode), Value, "", true);
	}

	void ActivateViewports(bool bEnable)
	{
		if (bViewportsEnabled == bEnable)
			return;
		
		bViewportsEnabled = bEnable;
		ESlateVisibility SlateVisibility = bEnable ? 
			ESlateVisibility::Visible : 
			ESlateVisibility::Collapsed;
		MaysViewport.SetVisibility(SlateVisibility);
		CodysViewport.SetVisibility(SlateVisibility);
	}

	void ActivateRTPCWidget(bool bEnable)
	{
		ESlateVisibility SlateVisibility = bEnable ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		RtpcWidget.SetVisibility(SlateVisibility);
	}

	void ActivateProfilerWidget(bool bEnable)
	{
		ESlateVisibility SlateVisibility = bEnable ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		ProfilerWidget.SetVisibility(SlateVisibility);
	}

	UFUNCTION(BlueprintCallable)
	void SwitchToNextTab(int Direction)
	{
		int CurrentIndex = int(SelectedDebugMode);
		int NumWidgets = int(EAudioDebugMode::NumOfModes);

		int NewIndex = CurrentIndex + Direction;

		if (NewIndex < 0)
			NewIndex = NumWidgets-1;
		
		if (NewIndex >= NumWidgets)
			NewIndex = 0;

		SelectedDebugMode = EAudioDebugMode(int(NewIndex));
		SelectedDebugText.SetText(FText::FromString(HazeAudio::ToString(SelectedDebugMode)));
	}

	UFUNCTION(BlueprintCallable)
	void DebugAllHazeAkComponents(bool bIsDebugging)
	{
		TArray<UHazeAkComponent> AkComps;
		UHazeAkComponent::GetAllHazeAkComponents(AkComps);
		
		for(UHazeAkComponent& AkComp : AkComps)
		{
			AkComp.SetDebugAudio(bIsDebugging);
		}
	}

	UFUNCTION(BlueprintCallable)
	void DebugAllAmbientZones(bool bIsDebugging, TArray<AAmbientZone> AllAmbientZones)
	{
		for(AAmbientZone& AmbZone : AllAmbientZones)
		{
			AmbZone.bDebug = bIsDebugging;
			AmbZone.AmbEventComp.SetDebugAudio(bIsDebugging);
			for(UHazeAkComponent Comp : AmbZone.RandomSpotsAkComps)
			{										
				Comp.SetDebugAudio(bIsDebugging);
			}
		} 
	}

	UFUNCTION(BlueprintCallable)
	void DebugAllAudioSplines(bool bIsDebugging, TArray<AAudioSpline> AllAudioSplines)
	{
		for(AAudioSpline& AudioSpline : AllAudioSplines)
		{
			AudioSpline.SetDebug(bIsDebugging);
		}
	}

	UFUNCTION(BlueprintCallable)
	void DebugPlayersAkComponents(bool bIsDebugging)
	{
		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayerHazeAkComp.SetDebugAudio(bIsDebugging);
		}
	}

	UFUNCTION(BlueprintCallable)
	void DebugEnableMusic(bool bEnableMusic)
	{
		HazeAudio::SetGlobalRTPC(HazeAudio::RTPC::DebugMusicToggleVolume, bEnableMusic ? 1 : 0);
	}

	UFUNCTION(BlueprintCallable)
	void DebugEnableVO(bool bEnableVO)
	{
		HazeAudio::SetGlobalRTPC(HazeAudio::RTPC::DebugVOToggleVolume, bEnableVO ? 1 : 0);
	}

	UFUNCTION(BlueprintCallable)
	void DebugEnableSFX(bool bEnableSFX)
	{
		HazeAudio::SetGlobalRTPC(HazeAudio::RTPC::DebugSFXToggleVolume, bEnableSFX ? 1 : 0);
	}

	UFUNCTION(BlueprintCallable)
	void EnableListenerPanningFeatureFlag(bool bEnable)
	{
		Audio::SetHazeFeatureFlag(1 << 1, bEnable);
	}

	UFUNCTION(BlueprintCallable)
	void EnableSkipAuxListenerFeatureFlag(bool bEnable)
	{
		// Audio::SetHazeFeatureFlag(1 << 2, bEnable);
		// Audio::SetHazeFeatureFlag(1 << 0, bEnable);
		Audio::SetHazeFeatureFlag(1 << 5, bEnable);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeo, FFocusEvent InFocusEvent)
	{
		return FEventReply::Handled().SetUserFocus(ButtonVerticalBox, true);
	}

	bool IsAnyDebugActive()
	{
		if (SelectedDebugMode != EAudioDebugMode::None)
			return true;

		for	(auto KeyValuePair : DebugButtons)
		{
			UAudioDebugMenuButton Button = KeyValuePair.Value;
			if (Button.IsDebugEnabled())
				return true;
		}

		return false;
	}

	bool IsDebugEnabled(EAudioDebugMode DebugMode)
	{
		UAudioDebugMenuButton Button;
		if (!DebugButtons.Find(DebugMode, Button))
			return HazeAudio::IsDebugEnabled(DebugMode);

		return 
			Button.IsDebugEnabled() || 
			SelectedDebugMode == DebugMode ||
			HazeAudio::IsDebugEnabled(DebugMode);
	}

	// UFUNCTION(BlueprintOverride)
	// void Tick(FGeometry MyGeometry, float InDeltaTime)
	// {	
	
	// }

	void UpdateWAAPI() 
	{
		auto Global = Cast<UAudioDebugMenuTabWidgetGlobals>(TabSwitcher.GetActiveWidget());
		if (Global != nullptr) 
		{
			if (Audio::IsWaapiConnected()) 
			{
				FAKWaapiJsonObject Json = Audio::CallWaapi(WaapiFunctionEndpoint::ProfilerGetVoices);
				TArray<FWaapiVoiceData> Voices = Audio::ConvertToVoicesData(Json);
				Global.UpdateVoices(Voices);
			}
			else {
				Global.UpdateGameObjects();
			}
		}
	}
}