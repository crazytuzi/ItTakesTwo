enum EPatrolAudioActorType
{
	None,
	Male,
	Female
}

struct FPatrolAudioEvents
{
	UPROPERTY()
	UAkAudioEvent IdleEvent;

	UPROPERTY()
	UAkAudioEvent OnTackledEvent;

	// Currently only used by DevilBabies
	UPROPERTY()
	UAkAudioEvent OnDeathEvent;

	UPROPERTY()
	TArray<FPatrolAudioAnimationInteractions> AnimationInteractions;

	UPROPERTY()
	EPatrolAudioActorType ActorType = EPatrolAudioActorType::None;

	bool IsEmptyPatrolData()
	{
		return IdleEvent == nullptr && 
		OnTackledEvent == nullptr &&
		AnimationInteractions.Num() == 0;
	}
}

struct FPatrolAudioAnimationInteractions
{
	UPROPERTY()
	UAkAudioEvent AnimationEvent;

	UPROPERTY()
	FName AnimationTag;
}


