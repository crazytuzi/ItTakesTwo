USTRUCT()
struct FHazeAudioEventStruct
{
	UPROPERTY()
	UAkAudioEvent Event;

	UPROPERTY()
	FName Tag;

	UPROPERTY()
	EHazeAudioPostEventType PostEventType = EHazeAudioPostEventType::Ambience;

	UPROPERTY()
	bool bPlayOnStart;

	UPROPERTY()
	bool bStopOnDestroy;

	UPROPERTY()
	float FadeOutMs;

	UPROPERTY()
	EAkCurveInterpolation FadeOutCurve;

	UPROPERTY(NotVisible)
	TArray<int> PlayingIDs;	
}