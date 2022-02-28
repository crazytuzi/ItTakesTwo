import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionAudioManager;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionFXAudioComponent;

UClockworkLastBossExplosionAudioManager GetExplosionsAudioManagerComp()
{
	return UClockworkLastBossExplosionAudioManager::GetOrCreate(Game::GetWorldSettings());
}

void RegisterAudioFXObject(UClockworkLastBossExplosionAudioObjectBase ExplosionAudioComp)
{
	UClockworkLastBossExplosionAudioManager ExplosionAudioManager = GetExplosionsAudioManagerComp();
	if(ExplosionAudioManager != nullptr)
		ExplosionAudioManager.RegisterComponent(ExplosionAudioComp);
}

void UnregisterAudioFXObject(UClockworkLastBossExplosionAudioObjectBase ExplosionAudioComp)
{
	UClockworkLastBossExplosionAudioManager ExplosionAudioManager = GetExplosionsAudioManagerComp();
	if(ExplosionAudioManager != nullptr)
		ExplosionAudioManager.UnregisterComponent(ExplosionAudioComp);
}