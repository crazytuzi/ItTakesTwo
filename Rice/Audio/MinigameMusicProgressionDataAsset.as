enum EMiniGameMusicProgressionType
{
	TimeCountUp,
	TimeCountDown,
	Score
}

enum EMiniGameMusicProgressionTriggerType
{
	State,
	Stinger
}

struct FMinigameMusicProgressionData
{
	UPROPERTY()
	EMiniGameMusicProgressionType ProgressionType;
	UPROPERTY()
	EMiniGameMusicProgressionTriggerType ProgressionTriggerType;
	UPROPERTY()
	int32 ProgressionValue;
	UPROPERTY()
	FString MusicProgressionStateTrigger;
	UPROPERTY()
	bool bTriggerOnce = false;

	UPROPERTY(NotVisible)
	bool bCanTrigger = true;

	float LastWantedMusicProgressionValue = 0.f;
}

class UMinigameMusicProgressionDataAsset : UDataAsset
{
	UPROPERTY()
	TArray<FMinigameMusicProgressionData> MusicProgressionDatas;
	
	UPROPERTY()
	TArray<int32> OnPointGetStingerIncrements;
	
	UPROPERTY()
	float OnLeaderChangeStingerCooldown = 0.f;
}