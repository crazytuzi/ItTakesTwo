import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionDebrisAudioComponent;

class UClockworkLastBossExplosionAudioManager : UActorComponent
{
	TArray<UClockworkLastBossExplosionAudioObjectBase> AudioFXComps;
	TArray<UClockworkLastBossExplosionDebrisAudioComponent> DebrisComps;

	UFUNCTION()
	void RegisterComponent(const UClockworkLastBossExplosionAudioObjectBase& AudioFXComp)
	{
		AudioFXComps.Add(AudioFXComp);

		UClockworkLastBossExplosionDebrisAudioComponent DebrisComp = Cast<UClockworkLastBossExplosionDebrisAudioComponent>(AudioFXComp);
		if(DebrisComp != nullptr)
			DebrisComps.Add(DebrisComp);
	}	

	UFUNCTION()
	void UnregisterComponent(const UClockworkLastBossExplosionAudioObjectBase& AudioFXComp)
	{
		AudioFXComps.RemoveSwap(AudioFXComp);
		DebrisComps.RemoveSwap(Cast<UClockworkLastBossExplosionDebrisAudioComponent>(AudioFXComp));
	}	

	UFUNCTION()
	void SetCurrentTimeForAudioObjects(const float& NewCurrentTime)
	{
		for(auto AudioComp : AudioFXComps)
		{
			AudioComp.OnTimeChanged(NewCurrentTime);			
		}	
	}	

	UFUNCTION()
	void OnExplosionStarted()
	{
		for(auto AudioComp : AudioFXComps)
		{
			AudioComp.BeginExplosionStarted();			
		}
	}
}

