const FConsoleVariable CVar_MusicIntensityDebugInfo("Haze.MusicIntensityDebugInfo", 0);

event void FOnMusicIntensityShowDebugInfo();

enum EMusicIntensityLevel
{
	None,
	Ambient,
	Threat,
	Combat,
}

struct FMusicIntensityEntry
{
	EMusicIntensityLevel Intensity;
	UObject Instigator;
}

struct FMusicStateOverride
{
	EMusicIntensityLevel Intensity;
	FName State;
	UObject Instigator;
}

class UMusicIntensityLevelComponent : UActorComponent
{
	private EMusicIntensityLevel CurrentIntensity = EMusicIntensityLevel::Ambient;
	private TArray<FMusicIntensityEntry> Entries;

	UPROPERTY(BlueprintReadOnly, Category = "Music Intensity")
	FName StateGroup = NAME_None;

	UPROPERTY(BlueprintReadOnly, Category = "Music Intensity")
	TMap<EMusicIntensityLevel, FName> StateMap;

	TMap<EMusicIntensityLevel, FName> DefaultStateMap;
	TArray<FMusicStateOverride> StateOverrides;

	// Default delay to use by enemies etc before they clear their intensity level (usually returning intensity to ambient) 
	UPROPERTY(Category = "Music Intensity")
	float ClearIntensityDelay = 10.f;

	// Default delay to use by enemies etc before they lower intensity level from combat to threat.
	UPROPERTY(Category = "Music Intensity")
	float CombatToThreatDelay = 6.f;

	UPROPERTY(Category = "Debug")
	FOnMusicIntensityShowDebugInfo OnShowDebugInfo;

	TArray<UObject> Disablers;

	void Disable(UObject Instigator)
	{
		Disablers.AddUnique(Instigator);
	}

	void Enable(UObject Instigator)
	{
		bool bWasDisabled = !IsEnabled();
		Disablers.Remove(Instigator);
		CleanDisablers();
		if (bWasDisabled && IsEnabled())
		{
			// Force update setting music state
			CurrentIntensity = EMusicIntensityLevel::None;
			UpdateIntensity();
		}
	}

	bool IsEnabled()
	{
		return (Disablers.Num() == 0);
	}

	void ApplyIntensity(EMusicIntensityLevel IntensityLevel, UObject Instigator)
	{
		ClearIntensityInternal(Instigator);

		// Insert sort, descending order
		int i = 0;
		for (; i < Entries.Num(); i++)
		{
			if (Entries[i].Intensity <= IntensityLevel)
				break;
		}
		FMusicIntensityEntry NewEntry;
		NewEntry.Intensity = IntensityLevel;
		NewEntry.Instigator = Instigator;
		Entries.Insert(NewEntry, i);				
		UpdateIntensity();
	}

	void ClearIntensityByInstigator(UObject Instigator)
	{
		ClearIntensityInternal(Instigator);
		UpdateIntensity();
	}

	UFUNCTION()
	EMusicIntensityLevel GetIntensity()
	{
		return CurrentIntensity;
	}

	void ClearIntensityInternal(UObject Instigator)
	{
		for (int i = Entries.Num() - 1; i >= 0; i--)
		{
			if ((Entries[i].Instigator == Instigator) || !System::IsValid(Entries[i].Instigator))
				Entries.RemoveAt(i);
		}
	}

	private void UpdateIntensity()
	{
		EMusicIntensityLevel NewIntensity = (Entries.Num() > 0) ? Entries[0].Intensity : EMusicIntensityLevel::Ambient;
		if (NewIntensity != CurrentIntensity)
		{
			CurrentIntensity = NewIntensity;
			if (StateGroup == NAME_None)
				return;

			FName State = GetStateName(NewIntensity);
			if (State == NAME_None)
				return;

			CleanDisablers();
			if (IsEnabled())
				AkGameplay::SetState(StateGroup, State);
		}
	}

	void CleanDisablers()
	{
		for (int i = Disablers.Num() - 1; i >= 0; i--)
		{
			if (!System::IsValid(Disablers[i]))
				Disablers.RemoveAtSwap(i);
		}
	}

	FName GetStateName(EMusicIntensityLevel IntensityLevel)
	{
		FName State = NAME_None;
		StateMap.Find(IntensityLevel, State);
		return State;
	}

	void ApplyMusicStateOverride(const FMusicStateOverride& Override)
	{
		if (!System::IsValid(Override.Instigator))
			return;

		if (DefaultStateMap.Num() == 0)
		{
			// First override, save defaults
			DefaultStateMap = StateMap;
		}

		// Override state map.
		StateMap.Add(Override.Intensity, Override.State);

		// Keep track of overrides so we can fall back to earlier overrides or defaults.
		StateOverrides.Add(Override);
	}

	void ClearMusicStateOverrideByInstigator(UObject Instigator)
	{
		if (StateOverrides.Num() == 0)
			return;

		// Clear out all entries by instigator (as well as invalid ones)
		for (int i = StateOverrides.Num() - 1; i >= 0; i--)
		{
			if ((StateOverrides[i].Instigator == Instigator) || !System::IsValid(StateOverrides[i].Instigator))
				StateOverrides.RemoveAt(i);
		}

		// Rebuild state map
		StateMap = DefaultStateMap;
		for (const FMusicStateOverride& Override : StateOverrides)
		{
			StateMap.Add(Override.Intensity, Override.State);
		}
	}


#if TEST
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CVar_MusicIntensityDebugInfo.GetInt() == 1)
		{
			Console::SetConsoleVariableInt("Haze.MusicIntensityDebugInfo", 0, "", true);
			OnShowDebugInfo.Broadcast();
#if EDITOR
			bHazeEditorOnlyDebugBool = true;
#endif
		}
#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			if (!IsEnabled())
			{
				PrintToScreenScaled("Music intensity: " + CurrentIntensity + " DISABLED", Scale = 2.f);
			}
			else
			{
				PrintToScreenScaled("    State: " + GetStateName(CurrentIntensity) + "    Group: " + StateGroup, Color = FLinearColor::Yellow, Scale = 1.5f);
				PrintToScreenScaled("Music intensity: " + CurrentIntensity, Scale = 2.f);
			}
		}
#endif
	}
#endif
}

namespace MusicIntensityLevel
{
	UFUNCTION()
	void ApplyMusicIntensityLevel(EMusicIntensityLevel Intensity, UObject Instigator)
	{
		UMusicIntensityLevelComponent MusicIntensityComp = GetMusicIntensityLevelComponent();
		if (MusicIntensityComp != nullptr)
			MusicIntensityComp.ApplyIntensity(Intensity, Instigator);
	}

	UFUNCTION()
	void ClearMusicIntensityLevelByInstigator(UObject Instigator)
	{
		UMusicIntensityLevelComponent MusicIntensityComp = GetMusicIntensityLevelComponent();
		if (MusicIntensityComp != nullptr)
			MusicIntensityComp.ClearIntensityByInstigator(Instigator);
	}

	// Music intensity level will stop affecting music state until enabled again
	UFUNCTION()
	void DisableMusicIntensityLevel(UObject Instigator)
	{
		UMusicIntensityLevelComponent MusicIntensityComp = GetMusicIntensityLevelComponent();
		if (MusicIntensityComp != nullptr)
			MusicIntensityComp.Disable(Instigator);		
	}

	// Music intensity level will affect music state again if previously disabled
	UFUNCTION()
	void EnableMusicIntensityLevel(UObject Instigator)
	{
		UMusicIntensityLevelComponent MusicIntensityComp = GetMusicIntensityLevelComponent();
		if (MusicIntensityComp != nullptr)
			MusicIntensityComp.Enable(Instigator);		
	}

	UFUNCTION()
	UMusicIntensityLevelComponent GetMusicIntensityLevelComponent()
	{
		AHazeMusicManagerActor MusicManager = UHazeAkComponent::GetMusicManagerActor();
		if (MusicManager == nullptr)
			return nullptr;
		return UMusicIntensityLevelComponent::Get(MusicManager);
	} 

	UFUNCTION()
	void ApplyMusicStateOverride(EMusicIntensityLevel Intensity, FName State, UObject Instigator)
	{
		UMusicIntensityLevelComponent MusicIntensityComp = GetMusicIntensityLevelComponent();
		if (MusicIntensityComp == nullptr)
			return;

		FMusicStateOverride Override;
		Override.Intensity = Intensity;
		Override.State = State;
		Override.Instigator = Instigator;
		MusicIntensityComp.ApplyMusicStateOverride(Override);
	}

	UFUNCTION()
	void ClearMusicStateOverrideByInstigator(UObject Instigator)
	{
		UMusicIntensityLevelComponent MusicIntensityComp = GetMusicIntensityLevelComponent();
		if (MusicIntensityComp == nullptr)
			return;
		MusicIntensityComp.ClearMusicStateOverrideByInstigator(Instigator);
	}
}