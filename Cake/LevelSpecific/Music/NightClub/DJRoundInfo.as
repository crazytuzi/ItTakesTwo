import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;


struct FDJRoundInfo
{
	UPROPERTY()
	TSet<EDJStandType> StationType;

	UPROPERTY()
	bool bIsDanceRound = false;

	UPROPERTY(meta = (EditCondition = "bIsDanceRound"))
	float DanceStationActiveTime = 10.0f;

	UPROPERTY(meta = (DisplayName = "Delay Before Start"))
	float TimeBeforeStart = 1.0f;

	UPROPERTY(meta = (DisplayName = "Delay After Stopped"))
	float TimeBeforeStop = 1.0f;
}
