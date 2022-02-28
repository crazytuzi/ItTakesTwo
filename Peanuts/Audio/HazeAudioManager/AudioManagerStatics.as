import Peanuts.Audio.HazeAudioManager.HazeAudioManager;

UFUNCTION(BlueprintPure)
UHazeAudioManager GetAudioManager()
{	
	return Cast<UHazeAudioManager>(Game::GetSingleton(UHazeAudioManager::StaticClass()));	 
}

UFUNCTION(BlueprintPure)
float GetPanningMultiplierValue()
{
	UHazeAudioManager AudioManager = GetAudioManager();	
	return AudioManager != nullptr ? AudioManager.PanningMultiplierValue : 1.f;
}