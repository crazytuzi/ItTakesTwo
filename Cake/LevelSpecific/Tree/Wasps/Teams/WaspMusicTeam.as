import Vino.Audio.Music.MusicIntensityLevelComponent;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;

class UWaspMusicTeam : UHazeAITeam
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
		BindDelegates(Member);		
	}

	void BindDelegates(AHazeActor Member)
	{
		// Bind relevant delegates to update music intensity.
		UWaspBehaviourComponent	BehaviourComp = UWaspBehaviourComponent::Get(Member);
		if (BehaviourComp != nullptr)
		{
			BehaviourComp.OnAliveForAWhile.AddUFunction(this, n"ReportThreat");
			BehaviourComp.OnDisabled.AddUFunction(this, n"ReportThreatOver");
			BehaviourComp.OnFlee.AddUFunction(this, n"ReportThreatOver");
			BehaviourComp.OnTelegraphingAttack.AddUFunction(this, n"ReportCombat");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		UnbindDelegates(Member); 
		ReportThreatOver(Member);
	}

	void UnbindDelegates(AHazeActor Member)
	{
		UWaspBehaviourComponent	BehaviourComp = UWaspBehaviourComponent::Get(Member);
		if (BehaviourComp != nullptr)
		{
			BehaviourComp.OnAliveForAWhile.Unbind(this, n"ReportThreat");
			BehaviourComp.OnDisabled.Unbind(this, n"ReportThreatOver");
			BehaviourComp.OnFlee.Unbind(this, n"ReportThreatOver");
			BehaviourComp.OnTelegraphingAttack.Unbind(this, n"ReportCombat");
		}
	}

	bool IsValidThreat(AHazeActor Enemy)
	{
		UWaspBehaviourComponent BehaviourComp = UWaspBehaviourComponent::Get(Enemy);
		if ((BehaviourComp == nullptr) || (BehaviourComp.State == EWaspState::Flee))
			return false;
		return true;
	}

	UFUNCTION()
	void ReportThreat(AHazeActor Enemy)
	{
		if (!IsValidThreat(Enemy))
			return;

		Threats.AddUnique(Enemy);
		IncreaseMusicIntensity(EMusicIntensityLevel::Threat);
	}

	UFUNCTION()
	void ReportCombat(AHazeActor Enemy)
	{
		if (!IsValidThreat(Enemy))
			return;

		Combatants.AddUnique(Enemy);
		IncreaseMusicIntensity(EMusicIntensityLevel::Combat);
	}

	UFUNCTION()
	void ReportThreatOver(AHazeActor Enemy)
	{
		Threats.RemoveSwap(Enemy);
		Combatants.RemoveSwap(Enemy);
		CleanDangerLists();

		if (MusicIntensityComp == nullptr)
			return;

		if ((Combatants.Num() == 0) && (CurrentMusicIntensity > EMusicIntensityLevel::Threat))
			System::SetTimer(this, n"OnClearedCombatDelay", MusicIntensityComp.CombatToThreatDelay, false);

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
		{
			// Music intensity component is no longer valid (e.g. after checkpoint restart)
			// We'll get a new one when new members join, meanwhile we reset intensity.
			CurrentMusicIntensity = EMusicIntensityLevel::Ambient;
			return;
		}
		else if (MusicIntensityComp.GetIntensity() < CurrentMusicIntensity)
		{
			CurrentMusicIntensity = MusicIntensityComp.GetIntensity();			
		}

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
		{
			// Music intensity component is no longer valid (e.g. after checkpoint restart)
			// We'll get a new one when new members join, meanwhile we reset intensity.
			CurrentMusicIntensity = EMusicIntensityLevel::Ambient;
			return;
		}
		else if (MusicIntensityComp.GetIntensity() < CurrentMusicIntensity)
		{
			CurrentMusicIntensity = MusicIntensityComp.GetIntensity();			
		}

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
		Info += "Wasp music team\n";
		Info += "  Threats:\n";
		for (AHazeActor Threat : Threats)
		{
			Info += "    " + Threat.GetName() + "\n";
		}	
		Info += "  Combatants:\n";
		for (AHazeActor Combatant : Combatants)
		{
			Info += "    " + Combatant.GetName() + "\n";
		}	
		PrintScaled(Info);
	}
}

namespace WaspMusicIntensity
{
	UFUNCTION()
	void SetWaspInitialMusicIntensity(EMusicIntensityLevel Intensity, float AmbientDelay)
	{
		UWaspMusicTeam Team = Cast<UWaspMusicTeam>(HazeAIBlueprintHelper::GetTeam(n"WaspMusicIntensityTeam"));
		if (Team != nullptr)
		{
			// Force team to set given intensity. Will last until team decides to set or clear intensity by itself.
			Team.SetInitialIntensity(Intensity, AmbientDelay);
		}
	}
}
