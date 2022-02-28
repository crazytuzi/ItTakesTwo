import Rice.DebugMenus.Capability.CapabilityDebugList;

UFUNCTION(BlueprintPure)
FString ConvertIntToString(int NumberToConvert, int LeastAmountNumbers)
{
	FString Output = "" + NumberToConvert;

	int NumbersLeft = LeastAmountNumbers - Output.Len();
	for (; NumbersLeft > 0; --NumbersLeft)
	{
		Output = "  " + Output;
	}

	return Output;
}

UCLASS(Config = Editor)
class UCapabilityDebugSystem : UHazeCapabilityComponentDebugSystem
{
    TArray<UHazeCapability> PreviousFramesCapabilities;

	UPROPERTY(Config)
	FString SelectedActor;

	UPROPERTY(Config)
	FString SelectedCategory = "Gameplay";

	UPROPERTY(Config)
	FString SelectedCapability;

	UPROPERTY()
	UCapabilityDebugListWidget ListWidget;

	bool bRestoring = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		bRestoring = true;
		RestorePreviousState();
		ListWidget.MakeSearchFilter(GetStoredSearchFilter());
		StoreSearchFilter(GetStoredSearchFilter());
		bRestoring = false;
	}

	UFUNCTION(BlueprintEvent)
	void RestorePreviousState()
	{
		// Implemented in widget bp
	}

    UFUNCTION(BlueprintOverride)
    void OnComponentToDebugChanged()
    {
		PreviousFramesCapabilities.Reset();
		if(ComponentToDebug != nullptr)
		{
       		PreviousFramesCapabilities.Append(ComponentToDebug.Capabilities);
			SelectedActor = ComponentToDebug.Owner.Name;
			SaveConfig();
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnCapabilityToDebugChanged()
	{
		if(!bRestoring && CapabilityToDebug != nullptr)
		{
			SelectedCapability = CapabilityToDebug.Class.Name;
			SaveConfig();
		}
	}

	UFUNCTION()
	void SaveCategory(FString Category)
	{
		SelectedCategory = Category;
		SaveConfig();
	}

	UFUNCTION()
	FString GetActiveSheetAsString()
	{
		if (ComponentToDebug != nullptr)
			return ComponentToDebug.GetActiveSheetName();
		return "";
	}

    UFUNCTION(BlueprintOverride)
    void Tick(FGeometry Geometry, float DeltaTime)
    {
        if (ComponentToDebug == nullptr)
            return;

        TArray<UHazeCapability> CapabilitiesToAdd;
        TArray<UHazeCapability> CapabilitiesToRemove = PreviousFramesCapabilities;
        for (UHazeCapability Capability : ComponentToDebug.Capabilities)
        {
            if (!PreviousFramesCapabilities.Contains(Capability))
            CapabilitiesToAdd.Add(Capability);

            CapabilitiesToRemove.RemoveSwap(Capability);
		}

		bool RerunComponentSetup = false;
        for (UHazeCapability Capability : CapabilitiesToRemove)
        {
			if (Capability != nullptr)
			{
				RerunComponentSetup = true;
				OnCapabilityWasRemoved(Capability);
			}
               
        }
        for (UHazeCapability Capability : CapabilitiesToAdd)
        {
			if (Capability != nullptr)
			{
				RerunComponentSetup = true;
				OnCapabilityWasAdded(Capability);
			}     
        }

		if (RerunComponentSetup)
		{
			SetComponentToDebug(ComponentToDebug);
		}
		else
		{
       		PreviousFramesCapabilities.Reset();
        	PreviousFramesCapabilities.Append(ComponentToDebug.Capabilities);
		}

		if(ListWidget != nullptr)
		{
			if(ListWidget.bIsDirrty)
			{
				ListWidget.bIsDirrty = false;
				StoreSearchFilter(ListWidget.GetFilterFieldText());
				SaveConfig();
			}
		}
			
    }

    UFUNCTION(BlueprintEvent)
    void OnCapabilityWasAdded(UHazeCapability Capability)
	{
		SetComponentToDebug(ComponentToDebug);
	}

    UFUNCTION(BlueprintEvent)
    void OnCapabilityWasRemoved(UHazeCapability Capability) 
	{
		SetComponentToDebug(nullptr);
	}
}
