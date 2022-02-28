import Vino.Control.DebugShortcutsEnableCapability;

class UDebugTimeHazeWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	bool ShowPaused = false;

	UPROPERTY(BlueprintReadOnly)
	float CurrentTimeDilation = 1.f;

	UFUNCTION(BlueprintPure)
	ESlateVisibility GetVisibilityType()const
	{
		if(ShowPaused)
			return ESlateVisibility::Visible;

		if(CurrentTimeDilation != 1.f)
			return ESlateVisibility::Visible;

		return ESlateVisibility::Collapsed;
	}

	UFUNCTION(BlueprintPure)
	FString DebugText()const
	{
		if(ShowPaused)
			return "PAUSED";

		FString OutText = "Debug Dilation: ";
		OutText += TrimFloatValue(CurrentTimeDilation);
		return OutText;
	}
}

class UDebugTimeComponent : UHazeDebugTimeComponent
{
	UPROPERTY(NotEditable)
	UDebugTimeHazeWidget CreatedWidget;

	TSubclassOf<UDebugTimeHazeWidget> WidgetClass;
	TArray<float> DilationAmounts;
	int DilationIndex = -1;
	bool bIsPaused = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DilationAmounts.Add(0);
		DilationAmounts.Add(0.025);
		DilationAmounts.Add(0.05);
		DilationAmounts.Add(0.1);
		DilationAmounts.Add(0.25);
		DilationAmounts.Add(0.5);
		DilationAmounts.Add(1);
		DilationAmounts.Add(2);
		DilationAmounts.Add(4);
		DilationAmounts.Add(6);
		DilationAmounts.Add(8);

		DilationIndex = DilationAmounts.FindIndex(1.f);
		if(DilationIndex < 0)
			DilationIndex = 0;

		SetDebugTimeDilation(DilationAmounts[DilationIndex]);
	}

	void SetupWidet(TSubclassOf<UDebugTimeHazeWidget> TimeWidget)
	{
		WidgetClass = TimeWidget;
	}

	void UpdateWidget(float NewTimeDilation)
	{
		if(CreatedWidget != nullptr)
		{
			if (NewTimeDilation == 1.f)
			{
				Widget::RemoveFullscreenWidget(CreatedWidget);
				CreatedWidget = nullptr;
			}
		}
		else
		{
			if (NewTimeDilation != 1.f)
			{
				CreatedWidget = Cast<UDebugTimeHazeWidget>(Widget::AddFullscreenWidget(WidgetClass, EHazeWidgetLayer::Dev));
				if(CreatedWidget != nullptr)
				{
					CreatedWidget.SetWidgetPersistent(true);
					CreatedWidget.ShowPaused = bIsPaused;
					CreatedWidget.CurrentTimeDilation = GetDebugTimeDilation();
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (CreatedWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(CreatedWidget);
			CreatedWidget = nullptr;
		}
	}

	UFUNCTION(NetFunction)
	void NetSetNewDilationIndex(int NewIndex)
	{
		SetDebugTimeDilation(DilationAmounts[NewIndex]);
		UpdateWidget(DilationAmounts[NewIndex]);
		DilationIndex = NewIndex;

		if(CreatedWidget != nullptr)
			CreatedWidget.CurrentTimeDilation = GetDebugTimeDilation();
	}

	UFUNCTION(NetFunction)
	void NetSwapPause()
	{
		if(bIsPaused)
		{
			// UNPAUSE
			SetDebugTimeDilation(DilationAmounts[DilationIndex]);
			UpdateWidget(DilationAmounts[DilationIndex]);
		}
		else
		{
			// PAUSE
			SetDebugTimeDilation(0.f);
			UpdateWidget(0.f);
		}

		bIsPaused = !bIsPaused;	
		if(CreatedWidget != nullptr)
			CreatedWidget.ShowPaused = bIsPaused;
	}
}

class UDebugTimeDilationCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"Time");

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 1;

	bool bShouldSwapPause = false;
	int NewDilationIndex = -1;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDebugTimeHazeWidget> TimeWidget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
   		auto PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		if(PlayerOwner.IsCody())
		{
			auto TimeComponent = UDebugTimeComponent::GetOrCreate(PlayerOwner);
			TimeComponent.SetupWidet(TimeWidget);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		// Increase	
		{	
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"TimeDilationUp", "Increase Deltatime Speed");
			Handler.AddPassiveUserButton(EHazeDebugPassiveUserCategoryButtonType::DPadUp);
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::Plus);
			Handler.DisplayAsDefault();
		}

		// Decrease
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"TimeDilationDown", "Decrease Deltatime Speed");
			Handler.AddPassiveUserButton(EHazeDebugPassiveUserCategoryButtonType::DPadDown);
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::Minus);
			Handler.DisplayAsDefault();
		}

		// Pause
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"Pause", "Stop everything from moving");
			Handler.AddActiveUserIgnoreCategoryButton(EHazeDebugActiveCategoryAlwaysValidButtonType::StickRightPress);
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::Pause);
			Handler.DisplayAsDefault();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBlocked(FHazeDebugCapabilityBlockedData& Params)
	{
		Params.BlockFunctionCalls();
	}

	UFUNCTION(BlueprintOverride)
	void OnUnblocked(FHazeDebugCapabilityBlockedData& Params) 
	{
		Params.UnblockFunctionCalls();
	}

	UFUNCTION()
	void TimeDilationUp()
	{
		auto TimeComponent = UDebugTimeComponent::GetOrCreate(Game::GetCody());
		NewDilationIndex = FMath::Min(TimeComponent.DilationIndex + 1, TimeComponent.DilationAmounts.Num() - 1);
	}

	UFUNCTION()
	void TimeDilationDown()
	{
		auto TimeComponent = UDebugTimeComponent::GetOrCreate(Game::GetCody());
		NewDilationIndex = FMath::Max(TimeComponent.DilationIndex - 1, 0);
	}

	UFUNCTION()
	void Pause()
	{
		bShouldSwapPause = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (bShouldSwapPause || NewDilationIndex >= 0)
			return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		auto TimeComponent = UDebugTimeComponent::GetOrCreate(Game::GetCody());
		if(bShouldSwapPause)
		{
			if(TimeComponent.bIsPaused)
				ActivationParams.AddActionState(n"Unpause");
			else
				ActivationParams.AddActionState(n"Pause");
		}

		ActivationParams.AddNumber(n"NewDilationIndex", NewDilationIndex);
		ActivationParams.AddNumber(n"CurrentDilationIndex", TimeComponent.DilationIndex);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto TimeComponent = UDebugTimeComponent::GetOrCreate(Game::GetCody());
		if(TimeComponent.HasControl())
		{
			NewDilationIndex = ActivationParams.GetNumber(n"NewDilationIndex");
			int CurrentDilationIndex = ActivationParams.GetNumber(n"CurrentDilationIndex");
			if(NewDilationIndex >= 0 && TimeComponent.DilationIndex == CurrentDilationIndex)
				TimeComponent.NetSetNewDilationIndex(NewDilationIndex);
		
			if(ActivationParams.GetActionState(n"Pause"))
			{
				if(!TimeComponent.bIsPaused)
					TimeComponent.NetSwapPause();
			}
			else if(ActivationParams.GetActionState(n"Unpause"))
			{
				if(TimeComponent.bIsPaused)
					TimeComponent.NetSwapPause();
			}
		}
			
		NewDilationIndex = -1;
		bShouldSwapPause = false;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString InfoText = "Use: '+' / '-', or DPad Up / Down to increase or decrease Time Dilation\n";
		InfoText += "Use Right Stick Down to Toggle Pause\n";

		auto TimeComponent = UDebugTimeComponent::GetOrCreate(Game::GetCody());
		const float CurrentTimeDilation = TimeComponent.GetDebugTimeDilation();
		FString DebugText = "Current Value: " + CurrentTimeDilation;
		return InfoText + DebugText;
	}
};
