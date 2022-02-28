
USTRUCT()
struct FLevelMusicTransition
{
	// Example: playroom/dungeon, doesn't care about casing.
	UPROPERTY()
	FString LevelGroup;
	UPROPERTY()
	UAkAudioEvent MusicEvent;
	UPROPERTY()
	int32 FadeOutTimeMs = 500;
	UPROPERTY()
	EAkCurveInterpolation FadeOutCurve = EAkCurveInterpolation::Exp1;	
};

class ULevelLoadingMusicTransitionDataAsset : UDataAsset
{
	UPROPERTY()
	const FLevelMusicTransition DefaultTransition;
	
	UPROPERTY()
	const TArray<FLevelMusicTransition> Transitions;

	private TMap<FString, FLevelMusicTransition> TransitionsByLevelGroup;

	TMap<FString, FLevelMusicTransition>& TransitionsAsMap()
	{
		if (TransitionsByLevelGroup.Num() != 0)
			return TransitionsByLevelGroup;
		
		for(FLevelMusicTransition Transition: Transitions)
		{
			TransitionsByLevelGroup.Add(Transition.LevelGroup, Transition);
		}

		return TransitionsByLevelGroup;
	}

	void GetMusicTransitionByLevelGroup(const FString LevelGroup, FLevelMusicTransition& Transition)
	{
		auto Map = TransitionsAsMap();
		if (Map.Find(LevelGroup, Transition))
			return;

		Transition = DefaultTransition;
	}
};