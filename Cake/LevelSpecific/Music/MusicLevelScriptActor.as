import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Singing.SingingAudio.PowerfulSongAudioCapability;

enum EMusicLevelPowerfulSongAudio
{
	None,
	ConcertHall,
	Backstage,
	Classic,
	Nightclub
}

class AMusicLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	UHazeCapabilitySheet CodySheet = Asset("/Game/Blueprints/LevelSpecific/Music/MusicCodySheet.MusicCodySheet");

	UPROPERTY()
	UHazeCapabilitySheet MaySheet = Asset("/Game/Blueprints/LevelSpecific/Music/MusicMaySheet.MusicMaySheet");

	UFUNCTION()
	void InitializeMusicLevel(bool bAddSheets, TSubclassOf<UPowerfulSongAudioCapability> PowerfulSongAudio)
	{
		if (bAddSheets)
		{
			if (MaySheet != nullptr)
			{
				Game::GetMay().AddCapabilitySheet(MaySheet, EHazeCapabilitySheetPriority::Normal, this);
			}

			if (CodySheet != nullptr)
			{
				Game::GetCody().AddCapabilitySheet(CodySheet, EHazeCapabilitySheetPriority::Normal, this);
			}
		}	

		UClass PowerfulSongAudioCapability = PowerfulSongAudio.Get();
		if(PowerfulSongAudioCapability != nullptr)
			Game::GetMay().AddCapability(PowerfulSongAudioCapability);
	}

	UFUNCTION()
	void ApplyMusicSettings(UHazeComposableSettings SingingSettings, UHazeComposableSettings CymbalSettings)
	{
		Game::GetMay().ApplySettings(SingingSettings, this, EHazeSettingsPriority::Script);
		UCymbalComponent::Get(Game::GetCody()).GetCymbalActor().ApplySettings(CymbalSettings, this, EHazeSettingsPriority::Script);
	}

	UFUNCTION()
	void ClearMusicSettings()
	{
		Game::GetMay().ClearSettingsByInstigator(this);
		UCymbalComponent::Get(Game::GetCody()).GetCymbalActor().ClearSettingsByInstigator(this);
	}

	UFUNCTION()
	void SetLevelAbilitiesEnabledForPlayer(AHazePlayerCharacter Player, bool bEnabled)
	{
		if (bEnabled)
		{
			if (Player == Game::GetCody())
				Game::GetCody().UnblockCapabilities(n"Cymbal", this);
			else
			{
				Game::GetMay().UnblockCapabilities(n"SongOfLife", this);
				Game::GetMay().UnblockCapabilities(n"PowerfulSong", this);
			}
			
		}
		else
		{
			if (Player == Game::GetCody())
				Game::GetCody().BlockCapabilities(n"Cymbal", this);
			else
			{
				Game::GetMay().BlockCapabilities(n"SongOfLife", this);
				Game::GetMay().BlockCapabilities(n"PowerfulSong", this);
			}
		}
	}	
}