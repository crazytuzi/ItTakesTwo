class UCharacterTimeControlAudioComponent : UActorComponent
{
	UPlayerHazeAkComponent PlayerHazeAkComp;

	UPROPERTY()
	UAkAudioEvent BeginTimeControlEvent;

	UPROPERTY()
	UAkAudioEvent EndTimeControlEvent;

	UPROPERTY()
	UAkAudioEvent StartTimeManipulationForwardsEvent;

	UPROPERTY()
	UAkAudioEvent StartTimeManipulationBackwardsEvent;

	UPROPERTY()
	UAkAudioEvent StartTimeManipulationIdleEvent;

	UPROPERTY()
	UAkAudioEvent TimeManipulationFullyProgressedEvent;

	UPROPERTY()
	UAkAudioEvent TimeManipulationFullyReversedEvent;

	bool bHasStartedManipulating = false;		

	private FHazeAudioEventInstance ForwardsEventInstance;
	private FHazeAudioEventInstance BackwardsEventInstance;


	UFUNCTION()
	void BeginTimeControl()
	{
		PlayerHazeAkComp.HazePostEvent(BeginTimeControlEvent);
	}

	UFUNCTION()
	void StartManipulationForwards()
	{
		if(PlayerHazeAkComp.EventInstanceIsPlaying(BackwardsEventInstance))
			PlayerHazeAkComp.HazeStopEvent(BackwardsEventInstance.PlayingID);

		if(!PlayerHazeAkComp.EventInstanceIsPlaying(ForwardsEventInstance))
			ForwardsEventInstance = PlayerHazeAkComp.HazePostEvent(StartTimeManipulationForwardsEvent);
	}

	UFUNCTION()
	void StartManipulationBackwards()
	{
		if(PlayerHazeAkComp.EventInstanceIsPlaying(ForwardsEventInstance))
			PlayerHazeAkComp.HazeStopEvent(ForwardsEventInstance.PlayingID);

		if(!PlayerHazeAkComp.EventInstanceIsPlaying(BackwardsEventInstance))
			BackwardsEventInstance = PlayerHazeAkComp.HazePostEvent(StartTimeManipulationBackwardsEvent);
	}

	UFUNCTION()
	void StopManipulating()
	{
		if(bHasStartedManipulating)
			PlayerHazeAkComp.HazePostEvent(StartTimeManipulationIdleEvent);
	}

	UFUNCTION()
	void EndTimeControl()
	{
		PlayerHazeAkComp.HazePostEvent(EndTimeControlEvent);

		if(PlayerHazeAkComp.EventInstanceIsPlaying(ForwardsEventInstance))
			PlayerHazeAkComp.HazeStopEvent(ForwardsEventInstance.PlayingID);

		if(PlayerHazeAkComp.EventInstanceIsPlaying(BackwardsEventInstance))
			PlayerHazeAkComp.HazeStopEvent(BackwardsEventInstance.PlayingID);		
	}

	UFUNCTION()
	void TimeManipulationFullyProgressed()
	{
		if(bHasStartedManipulating)
			PlayerHazeAkComp.HazePostEvent(TimeManipulationFullyProgressedEvent);
	}

	UFUNCTION()
	void TimeManipulationFullyReversed()
	{
		if(bHasStartedManipulating)
			PlayerHazeAkComp.HazePostEvent(TimeManipulationFullyReversedEvent);	
	}
}