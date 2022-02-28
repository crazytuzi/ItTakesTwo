
class UComposableSettingsDebugMenu : UHazeDebugMenuScriptBase
{
	UPROPERTY()
	AHazeActor DebugActor;

	UPROPERTY()
	UHazeComposableSettingsComponent DebugComp;

	UPROPERTY()
	UClass DebugClass;

	TArray<UClass> SettingsClasses;
	TArray<UUserWidget> SettingsClassWidgets;

	TArray<FHazeComposableSettingsDebugLayer> DebugLayers;
	TArray<UUserWidget> DebugLayerWidgets;

	UObject LayerInstigator;
	UObject LayerAsset;
	EHazeSettingsPriority LayerPriority;

	UFUNCTION()
	void SetActorToDebug(AActor NewActor)
	{
		DebugActor = Cast<AHazeActor>(NewActor);
		DebugComp = UHazeComposableSettingsComponent::GetOrCreate(DebugActor);
	}

	UFUNCTION()
	void SetSettingsClassToDebug(UObject InClass)
	{
		DebugClass = Cast<UClass>(InClass);
	}

	UFUNCTION()
	void SetDebugLayerToDebug(UUserWidget Entry)
	{
		int Index = DebugLayerWidgets.FindIndex(Entry);
		if (Index == -1)
		{
			LayerAsset = nullptr;
			LayerInstigator = nullptr;
			return;
		}

		const FHazeComposableSettingsDebugLayer& DebugLayer = DebugLayers[DebugLayers.Num() - Index - 1];
		LayerAsset = DebugLayer.Asset;
		LayerInstigator = DebugLayer.Instigator;
		LayerPriority = DebugLayer.Priority;
	}

	UFUNCTION(BlueprintEvent)
	UUserWidget AddSettingsClass(UClass InClass)
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void RemoveSettingsClass(UUserWidget Widget)
	{
	}

	void UpdateSettingsClasses()
	{
		if (DebugComp == nullptr)
			return;

		TArray<UClass> SettingsTypes;
		DebugComp.DebugGetSettingsTypes(SettingsTypes);

		for (int i = 0, Count = SettingsClasses.Num(); i < Count; ++i)
		{
			if (!SettingsTypes.Contains(SettingsClasses[i]))
			{
				RemoveSettingsClass(SettingsClassWidgets[i]);
				SettingsClasses.RemoveAt(i);
				SettingsClassWidgets.RemoveAt(i);
				--i; --Count;
			}
		}

		for (auto Type : SettingsTypes)
		{
			if (!SettingsClasses.Contains(Type))
			{
				auto Widget = AddSettingsClass(Type);
				SettingsClasses.Add(Type);
				SettingsClassWidgets.Add(Widget);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	UUserWidget AddDebugLayer()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void RemoveDebugLayer(UUserWidget Widget)
	{
	}

	UFUNCTION(BlueprintEvent)
	void UpdateDebugLayer(UUserWidget Widget, const FHazeComposableSettingsDebugLayer& DebugLayer)
	{
	}

	void UpdateDebugLayers()
	{
		if (DebugComp == nullptr)
			return;
		if (DebugClass == nullptr)
			return;

		DebugComp.DebugDescribeSettingsType(DebugClass, DebugLayers);

		for (int i = DebugLayers.Num(), Count = DebugLayerWidgets.Num(); i < Count; ++i)
			RemoveDebugLayer(DebugLayerWidgets[i]);

		DebugLayerWidgets.SetNum(DebugLayers.Num());

		for (int i = 0, Count = DebugLayers.Num(); i < Count; ++i)
		{
			if (DebugLayerWidgets[i] == nullptr)
				DebugLayerWidgets[i] = AddDebugLayer();
			if (DebugLayerWidgets[i] == nullptr)
				continue;
			UpdateDebugLayer(DebugLayerWidgets[i], DebugLayers[Count - i - 1]);
		}
	}

	UFUNCTION()
	bool GetCurrentDebugLayer(FHazeComposableSettingsDebugLayer& OutLayer, int& OutIndex)
	{
		if (DebugLayers.Num() == 0)
			return false;

		for (int i = 0, Count = DebugLayers.Num(); i < Count; ++i)
		{
			auto& Layer = DebugLayers[i];
			if (Layer.Instigator != LayerInstigator)
				continue;
			if (Layer.Asset != LayerAsset)
				continue;
			if (Layer.Priority != LayerPriority)
				continue;

			OutLayer = Layer;
			OutIndex = i;
			return true;
		}

		OutIndex = DebugLayers.Num() - 1;
		OutLayer = DebugLayers[OutIndex];
		return true;
	}

	UFUNCTION(BlueprintPure)
	FString GetCurrentDebugLayerString()
	{
		FHazeComposableSettingsDebugLayer Layer;
		int LayerIndex = -1;
		if (!GetCurrentDebugLayer(Layer, LayerIndex))
			return "";

		FString Str;

		if (Layer.Asset != nullptr)
		{
			if (Layer.bIsTransientSettings)
				Str += "<Blue>Transient Settings</>";
			else
				Str += "Asset:\n    "+Layer.Asset.GetPathName();
			Str += "\n";
		}

		if (Layer.Instigator != nullptr)
		{
			Str += "Instigator:\n    "+Layer.Instigator.Name;
			Str += "\n";
		}

		Str += "Priority:\n    "+Debug::GetEnumDisplayName("EHazeSettingsPriority", int(Layer.Priority));
		Str += "\n\n";

		if (LayerIndex != DebugLayers.Num() - 1)
		{
			Str += "<Red>NOT HIGHEST PRIORITY</>\n";
		}

		Str += Layer.DebugString;

		return Str;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		UpdateSettingsClasses();
		UpdateDebugLayers();
	}
};