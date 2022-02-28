
class UAudioDebugMenuEventInstanceListItem : UHazeUserWidget
{
	FHazeAudioEventInstance EventInstance;

	UFUNCTION()
	FHazeAudioEventInstance GetItemData() 
	{
		return EventInstance;
	}

	UFUNCTION()
	void SetItemData(FHazeAudioEventInstance Data)  
	{
		EventInstance = Data;
	}
}	