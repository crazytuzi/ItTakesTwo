import Vino.Audio.Music.MusicIntensityLevelComponent;

class UMusicIntensityTeam : UHazeAITeam
{
	UMusicIntensityLevelComponent MusicIntensityComp = nullptr;
	EMusicIntensityLevel CurrentMusicIntensity = EMusicIntensityLevel::Ambient;

	EMusicIntensityLevel PendingInitialIntensity = EMusicIntensityLevel::None;
	float ClearThreatDelayOverride = -1.f;

	TArray<AHazeActor> Combatants;
	TArray<AHazeActor> Threats;

	UFUNCTION(BlueprintOverride)
	void OnMemberJoined(AHazeActor Member)
	{
		AHazeMusicManagerActor MusicManager = UHazeAkComponent::GetMusicManagerActor();
		if (MusicManager != nullptr)
		{
			UMusicIntensityLevelComponent NewMusicIntensityComp = UMusicIntensityLevelComponent::Get(MusicManager);
			if (MusicIntensityComp != NewMusicIntensityComp)
			{
				if (MusicIntensityComp != nullptr)
				{
					MusicIntensityComp.ClearIntensityByInstigator(this);
					MusicIntensityComp.OnShowDebugInfo.Unbind(this, n"ShowDebugInfo");
				}
				MusicIntensityComp = NewMusicIntensityComp;
				if (PendingInitialIntensity != EMusicIntensityLevel::None)
					SetInitialIntensity(PendingInitialIntensity, ClearThreatDelayOverride);
				NewMusicIntensityComp.OnShowDebugInfo.AddUFunction(this, n"ShowDebugInfo");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		ReportThreatOver(Member);
	}

	UFUNCTION()
	void ReportThreat(AHazeActor Enemy)
	{
		if (Enemy == nullptr)
			return;
		Threats.AddUnique(Enemy);
		IncreaseMusicIntensity(EMusicIntensityLevel::Threat);
	}

	UFUNCTION()
	void ReportCombat(AHazeActor Enemy)
	{
		if (Enemy == nullptr)
			return;
		Combatants.AddUnique(Enemy);
		IncreaseMusicIntensity(EMusicIntensityLevel::Combat);
	}

	UFUNCTION()
	void ReportThreatOver(AHazeActor Enemy)
	{
		if (Enemy == nullptr)
			return;

		Threats.RemoveSwap(Enemy);
		Combatants.RemoveSwap(Enemy);
		CleanDangerLists();

		if (MusicIntensityComp == nullptr)
			return;

		if ((Combatants.Num() == 0) && 
			(CurrentMusicIntensity > EMusicIntensityLevel::Threat) && 
			(MusicIntensityComp.StateMap.Contains(EMusicIntensityLevel::Threat)))
		{
			System::SetTimer(this, n"OnClearedCombatDelay", MusicIntensityComp.CombatToThreatDelay, false);
		}

		if ((Threats.Num() == 0) && (Combatants.Num() == 0))
		{
			float Delay = FMath::Max(MusicIntensityComp.ClearIntensityDelay, MusicIntensityComp.CombatToThreatDelay);
			if (ClearThreatDelayOverride >= 0.f)
				Delay = FMath::Max(0.001f, ClearThreatDelayOverride);
			System::SetTimer(this, n"OnClearedThreatsDelay", Delay, false);
		}
	}

	UFUNCTION()
	void OnClearedCombatDelay()
	{
		if (MusicIntensityComp == nullptr)
			return;

		CleanDangerLists();
		if ((Combatants.Num() == 0) && (CurrentMusicIntensity > EMusicIntensityLevel::Threat))
		{
			// Only apply threat when that might actually lower intensity (we might have set combat while intensity comp was disabled)
			if (MusicIntensityComp.GetIntensity() > EMusicIntensityLevel::Threat)
				MusicIntensityComp.ApplyIntensity(EMusicIntensityLevel::Threat, this);
			CurrentMusicIntensity = EMusicIntensityLevel::Threat;
		}
	}

	UFUNCTION()
	void OnClearedThreatsDelay()
	{
		if (MusicIntensityComp == nullptr)
			return;

		CleanDangerLists();
		if ((Threats.Num() == 0) && (Combatants.Num() == 0))
		{
			MusicIntensityComp.ClearIntensityByInstigator(this);
			CurrentMusicIntensity = EMusicIntensityLevel::Ambient;
			ClearThreatDelayOverride = -1.f;
		}
	}

	void IncreaseMusicIntensity(EMusicIntensityLevel Intensity)
	{
		if (MusicIntensityComp == nullptr)
			return;
		if (CurrentMusicIntensity < Intensity)
		{
			MusicIntensityComp.ApplyIntensity(Intensity, this);
			CurrentMusicIntensity = Intensity;
		}
	}

	void CleanDangerLists()
	{
		for (int i = Threats.Num() - 1; i >= 0; i--)
		{
			if (!System::IsValid(Threats[i]))
				Threats.RemoveAtSwap(i);
		}
		for (int i = Combatants.Num() - 1; i >= 0; i--)
		{
			if (!System::IsValid(Combatants[i]))
				Combatants.RemoveAtSwap(i);
		}
	}

	void SetInitialIntensity(EMusicIntensityLevel Intensity, float AmbientDelay)
	{
		ClearThreatDelayOverride = AmbientDelay;
		if (MusicIntensityComp == nullptr)
		{
			PendingInitialIntensity = Intensity;
			return;
		}
		PendingInitialIntensity = EMusicIntensityLevel::None;
		CurrentMusicIntensity = Intensity;
		MusicIntensityComp.ApplyIntensity(Intensity, this);
	}	

	UFUNCTION(NotBlueprintCallable)
	void ShowDebugInfo()
	{
		FString Info;
		Info += "Music intensity team\n";
		if (MusicIntensityComp.StateMap.Contains(EMusicIntensityLevel::Threat))
		{
			Info += "  Threats:\n";
			for (AHazeActor Threat : Threats)
			{
				Info += "    " + Threat.GetName() + "\n";
			}	
		}
		Info += "  Combatants:\n";
		for (AHazeActor Combatant : Combatants)
		{
			Info += "    " + Combatant.GetName() + "\n";
		}	
		PrintScaled(Info);
	}
}
