import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;

event void FDJSmokeMachineDelegate();
event void FDJSmokeMachineTickDelegate(float Progress);

class ADJStationSmokeMachine : ADJVinylPlayer
{
	UPROPERTY()
	FDJSmokeMachineDelegate OnSmokeStart;
	UPROPERTY()
	FDJSmokeMachineDelegate OnSmokeEnd;
	UPROPERTY()
	FDJSmokeMachineTickDelegate OnUpdateSmoke;

	bool bUpdateSmoke = false;
	int Counter = 0;

	void OnPlayerAnimationStart()
	{
		Super::OnPlayerAnimationStart();

		Counter++;

		if(Counter == 1)
		{
			bUpdateSmoke = true;
			OnSmokeStart.Broadcast();
			
		}
	}

	void OnPlayerAnimationEnd()
	{
		Super::OnPlayerAnimationEnd();

		Counter--;

		if(Counter == 0)
		{
			bUpdateSmoke = false;
			OnSmokeEnd.Broadcast();
			OnUpdateSmoke.Broadcast(0.0f);
			
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if(bUpdateSmoke)
		{
			OnUpdateSmoke.Broadcast(RelevantProgress);
		}
	}

	float GetRelevantProgress() const property
	{
		return SyncedProgress.Value;
	}
}
