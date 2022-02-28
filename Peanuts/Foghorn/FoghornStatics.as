import Peanuts.Foghorn.FoghornManager;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;

UFUNCTION(Category = "Foghorn", Meta = (Keywords="Barks", AdvancedDisplay = "ActorOverride"))
void PlayFoghornBark(UFoghornBarkDataAsset BarkDataAsset, AActor ActorOverride)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	if(BarkDataAsset == nullptr)
	{
		PrintError("PlayFoghornBark called with null BarkDataAsset");
		return;
	}

	if (BarkDataAsset.VoiceLines.Num() < 1)
	{
		PrintError("PlayFoghornBark called with empty BarkDataAsset " + BarkDataAsset.Name);
		return;
	}

	if (BarkDataAsset.PresetType == EFoghornPresetType::Preset && BarkDataAsset.Preset == nullptr)
	{
		PrintError("PlayFoghornBark called with BarkDataAsset " + BarkDataAsset.Name + " with empty Preset");
		return;
	}

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.PlayBark(BarkDataAsset, ActorOverride);
}

UFUNCTION(Category = "Foghorn", Meta = (Keywords="Barks", AdvancedDisplay = "ActorOverride"))
void PlayFoghornEffort(UFoghornBarkDataAsset BarkDataAsset, AActor ActorOverride)
{
	if(BarkDataAsset == nullptr)
	{
		PrintError("PlayFoghornEffort called with null BarkDataAsset");
		return;
	}

	if (BarkDataAsset.VoiceLines.Num() < 1)
	{
		PrintError("PlayFoghornEffort called with empty BarkDataAsset " + BarkDataAsset.Name);
		return;
	}

	if (BarkDataAsset.PresetType == EFoghornPresetType::Preset && BarkDataAsset.Preset == nullptr)
	{
		PrintError("PlayFoghornEffort called with BarkDataAsset " + BarkDataAsset.Name + " with empty Preset");
		return;
	}

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.PlayEffort(BarkDataAsset, ActorOverride);
}

UFUNCTION(Category="Foghorn", Meta = (Keywords="Bark,Barks", AdvancedDisplay = "ExtraActor,ExtraActor2,ExtraActor3,ExtraActor4") )
void PlayFoghornDialogue(UFoghornDialogueDataAsset DialogueDataAsset, AActor ExtraActor = nullptr, AActor ExtraActor2 = nullptr, AActor ExtraActor3 = nullptr, AActor ExtraActor4 = nullptr)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	if(DialogueDataAsset == nullptr)
	{
		PrintError("PlayFoghornDialogue called with null DialogueDataAsset");
		return;
	}

	if (DialogueDataAsset.VoiceLines.Num() < 1)
	{
		PrintError("PlayFoghornDialogue called with empty DialogueDataAsset " + DialogueDataAsset.Name);
		return;
	}

	if (DialogueDataAsset.PresetType == EFoghornPresetType::Preset && DialogueDataAsset.Preset == nullptr)
	{
		PrintError("PlayFoghornDialogue called with DialogueDataAsset " + DialogueDataAsset.Name + " with empty Preset");
		return;
	}

	FFoghornMultiActors Actors;
	Actors.Actor1 = ExtraActor;
	Actors.Actor2 = ExtraActor2;
	Actors.Actor3 = ExtraActor3;
	Actors.Actor4 = ExtraActor4;

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.PlayDialogue(DialogueDataAsset, Actors);
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void PauseFoghornActor(AActor Actor)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	if(Actor == nullptr)
	{
		PrintError("PauseFoghornActor called with null Actor");
		return;
	}

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.Pause(Actor);
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void PauseFoghornActorWithEffort(AActor Actor, UFoghornBarkDataAsset BarkDataAsset, AActor ActorOverride)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	if(Actor == nullptr)
	{
		PrintError("PauseFoghornActorWithEffort called with null Actor");
		return;
	}

	if(BarkDataAsset == nullptr)
	{
		PrintError("PauseFoghornActorWithEffort called with null BarkDataAsset");
		return;
	}

	if (BarkDataAsset.VoiceLines.Num() < 1)
	{
		PrintError("PauseFoghornActorWithEffort called with empty BarkDataAsset " + BarkDataAsset.Name);
		return;
	}

	if (BarkDataAsset.PresetType == EFoghornPresetType::Preset && BarkDataAsset.Preset == nullptr)
	{
		PrintError("PauseFoghornActorWithEffort called with BarkDataAsset " + BarkDataAsset.Name + " with empty Preset");
		return;
	}

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.PauseWithEffort(Actor, BarkDataAsset, ActorOverride);
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void StopFoghorn()
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.Stop();
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void ResumeFoghornActor(AActor Actor = nullptr)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.Resume(Actor);
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void ResumeFoghorn()
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.ResumeAll();
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void ResumeFoghornWithBark(AActor ActorToResume, UFoghornBarkDataAsset BarkDataAsset, AActor ActorOverride)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	if(ActorToResume == nullptr)
	{
		PrintError("ResumeFoghornWithBark called with null Actor");
		return;
	}

	if(BarkDataAsset == nullptr)
	{
		PrintError("ResumeFoghornWithBark called with null BarkDataAsset");
		return;
	}

	if (BarkDataAsset.VoiceLines.Num() < 1)
	{
		PrintError("ResumeFoghornWithBark called with empty BarkDataAsset " + BarkDataAsset.Name);
		return;
	}

	if (BarkDataAsset.PresetType == EFoghornPresetType::Preset && BarkDataAsset.Preset == nullptr)
	{
		PrintError("ResumeFoghornWithBark called with BarkDataAsset " + BarkDataAsset.Name + " with empty Preset");
		return;
	}

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.ResumeWithBark(ActorToResume, BarkDataAsset, ActorOverride);
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void ResumeFoghornWithDialogue(AActor ActorToResume, UFoghornDialogueDataAsset DialogueDataAsset, AActor ExtraActor)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	if(ActorToResume == nullptr)
	{
		PrintError("ResumeFoghornWithDialogue called with null Actor");
		return;
	}

	if(DialogueDataAsset == nullptr)
	{
		PrintError("ResumeFoghornWithDialogue called with null DialogueDataAsset");
		return;
	}

	if (DialogueDataAsset.VoiceLines.Num() < 1)
	{
		PrintError("ResumeFoghornWithDialogue called with empty DialogueDataAsset " + DialogueDataAsset.Name);
		return;
	}

	if (DialogueDataAsset.PresetType == EFoghornPresetType::Preset && DialogueDataAsset.Preset == nullptr)
	{
		PrintError("ResumeFoghornWithDialogue called with DialogueDataAsset " + DialogueDataAsset.Name + " with empty Preset");
		return;
	}

	FFoghornMultiActors Actors;
	Actors.Actor1 = ExtraActor;

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.ResumeWithDialogue(ActorToResume, DialogueDataAsset, Actors);
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks", AdvancedDisplay = "Actor,Actor2,Actor3,Actor4") )
void PlayFoghornVOBankEvent(UFoghornVOBankDataAssetBase VOBankDataAsset, FName EventName, AActor Actor = nullptr, AActor Actor2 = nullptr, AActor Actor3 = nullptr, AActor Actor4 = nullptr)
{
	if (VOBankDataAsset == nullptr)
		return;

	VOBankDataAsset.TriggerVO(EventName, Actor, Actor2, Actor3, Actor4);

	#if TEST
	if (CVar_FoghornVOBankDebug.GetInt() != 0)
	{
		FString LogText = VOBankDataAsset.Name.ToString() + " triggered with " + EventName.ToString();
		if (Actor != nullptr)
		{
			LogText += " on " + Actor.Name;
		}
		Log("Foghorn " + LogText);
		PrintToScreen(LogText, 3.0f);
	}
	#endif
}

UFUNCTION(Category="Foghorn", Meta=(Keywords="Bark,Barks") )
void SetFoghornMinigameModeEnabled(bool bEnabled)
{
	// Only trigger on May where May has control
	if (!Game::GetMay().HasControl())
		return;

	UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	FoghornManager.SetMinigameModeEnabled(bEnabled);
}

void SetCanPlayEfforts(UHazeAkComponent& HazeAkComp, const bool bCanPlay)
{
	const float CanPlayValue = bCanPlay ? 0.f : 1.f;
	HazeAkComp.SetRTPCValue("Rtpc_VO_Efforts_IsBlocked", CanPlayValue);
}


UFUNCTION()
bool FoghornDebugIsNarrationEnabled()
{
	#if TEST
	FString MenuNarration;
	bool Res = GameSettings::GetGameSettingsValue(n"MenuNarration", MenuNarration);
	if (Res == true)
	{
		return MenuNarration == "On";
	}
	#endif
	return false;
}
