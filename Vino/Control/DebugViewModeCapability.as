import Vino.Control.DebugShortcutsEnableCapability;

enum EDebugViewMode
{
    Normal,
    Unlit,
    Wireframe,
	Unshadowed,
    
    MAX,
    Invalid = EDebugViewMode::MAX,
};

class UDebugViewModeCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	EDebugViewMode CurrentMode = EDebugViewMode::Normal;
	bool bWantsCameraLightActive = false;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DebugViewMode_Normal", "ViewMode_Normal");
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::F1);
			Handler.DisplayAsDefault();
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DebugViewMode_Wireframe", "ViewMode_Wireframe");
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::F2);
			Handler.DisplayAsDefault();
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DebugViewMode_Unlit", "ViewMode_Unlit");
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::F3);
			Handler.DisplayAsDefault();
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DebugViewMode_Unshadowed", "ViewMode_Unshadowed");
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::F4);
			Handler.DisplayAsDefault();
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ToggleCameraLight", "ToggleCameraLight");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, Handler.DefaultActiveCategory);
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::F6);
		}


		{
			// This could be removed since we have a viewmode menu now
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DebugViewMode_Toggle", "DebugViewMode_Toggle");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, Handler.DefaultActiveCategory);
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SetNormalViewMode", "Normal");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"ViewMode");
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SetUnlitViewMode", "Unlit");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"ViewMode");
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SetWireframeViewMode", "Wireframe");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"ViewMode");
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SetUnshadowedViewMode", "Unshadowed");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, n"ViewMode");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SwitchToMode(EDebugViewMode::Normal);
		if(bWantsCameraLightActive)
		{
			System::ExecuteConsoleCommand("Haze.Camera.Light.Toggle");
		}
	}

	UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        SwitchToMode(EDebugViewMode::Normal);
		if(bWantsCameraLightActive)
		{
			System::ExecuteConsoleCommand("Haze.Camera.Light.Toggle");
		}
    }

	UFUNCTION(NotBlueprintCallable)
	void DebugViewMode_Normal()
	{
		SwitchToMode(EDebugViewMode::Normal);
	}

	UFUNCTION(NotBlueprintCallable)
	void DebugViewMode_Wireframe()
	{
		SwitchToMode(EDebugViewMode::Wireframe);
	}

	UFUNCTION(NotBlueprintCallable)
	void DebugViewMode_Unlit()
	{
		SwitchToMode(EDebugViewMode::Unlit);
	}

	UFUNCTION(NotBlueprintCallable)
	void DebugViewMode_Unshadowed()
	{
		SwitchToMode(EDebugViewMode::Unshadowed);
	}

	UFUNCTION(NotBlueprintCallable)
	void DebugViewMode_Toggle()
	{
		switch (CurrentMode)
		{
			case EDebugViewMode::Normal:
				SwitchToMode(EDebugViewMode::Unlit);
			break;
			case EDebugViewMode::Unlit:
				SwitchToMode(EDebugViewMode::Wireframe);
			break;
			case EDebugViewMode::Wireframe:
				SwitchToMode(EDebugViewMode::Unshadowed);
			break;
			case EDebugViewMode::Unshadowed:
				SwitchToMode(EDebugViewMode::Normal);
			break;
		}
	}

	
	UFUNCTION(NotBlueprintCallable)
	void ToggleCameraLight()
	{
		bWantsCameraLightActive = !bWantsCameraLightActive;
		if(bWantsCameraLightActive)
			Print("Showing Light", 2.f, FLinearColor::Red);
		else
			Print("Showing Normal", 2.f, FLinearColor::Green);
		System::ExecuteConsoleCommand("Haze.Camera.Light.Toggle");
	}
		
    void SwitchToMode(EDebugViewMode Mode)
    {
        switch (Mode)
        {
            case EDebugViewMode::Normal:
				SetNormalViewMode();
            break;
            case EDebugViewMode::Unlit:
				SetUnlitViewMode();
            break;
            case EDebugViewMode::Wireframe:
				SetWireframeViewMode();
            break;
            case EDebugViewMode::Unshadowed:
				SetUnshadowedViewMode();
            break;
        }
    }

	UFUNCTION(NotBlueprintCallable)
	void SetNormalViewMode()
	{
		CurrentMode = EDebugViewMode::Normal;
		System::ExecuteConsoleCommand("ShowFlag.Lighting 2");
		System::ExecuteConsoleCommand("ShowFlag.Wireframe 2");
		System::ExecuteConsoleCommand("ShowFlag.DynamicShadows 2");
	}

	
	UFUNCTION(NotBlueprintCallable)
	void SetUnlitViewMode()
	{
		CurrentMode = EDebugViewMode::Unlit;
		System::ExecuteConsoleCommand("ShowFlag.Lighting 0");
        System::ExecuteConsoleCommand("ShowFlag.Wireframe 0");
        System::ExecuteConsoleCommand("ShowFlag.DynamicShadows 0");
	}

	UFUNCTION(NotBlueprintCallable)
	void SetWireframeViewMode()
	{
		CurrentMode = EDebugViewMode::Wireframe;
		System::ExecuteConsoleCommand("ShowFlag.Lighting 1");
        System::ExecuteConsoleCommand("ShowFlag.Wireframe 1");
        System::ExecuteConsoleCommand("ShowFlag.DynamicShadows 0");
	}

	UFUNCTION(NotBlueprintCallable)
	void SetUnshadowedViewMode()
	{
		CurrentMode = EDebugViewMode::Unshadowed;
		System::ExecuteConsoleCommand("ShowFlag.Lighting 1");
        System::ExecuteConsoleCommand("ShowFlag.Wireframe 0");
        System::ExecuteConsoleCommand("ShowFlag.DynamicShadows 0");
	}
};