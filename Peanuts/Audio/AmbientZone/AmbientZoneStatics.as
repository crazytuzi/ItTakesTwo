import Peanuts.Audio.AmbientZone.AmbientZoneManager;
import Peanuts.Audio.AmbientZone.AmbientZone;

UAmbientZoneManager GetAmbientZoneManager()
{
	return Cast<UAmbientZoneManager>(Game::GetSingleton(UAmbientZoneManager::StaticClass()));
}

void RegisterAmbientZone(AAmbientZone AmbZone)
{
	UAmbientZoneManager Manager = GetAmbientZoneManager();
	Manager.RegisterAmbientZone(AmbZone);	
}

void UnregisterAmbientZone(AAmbientZone AmbZone)
{
	UAmbientZoneManager Manager = GetAmbientZoneManager();
	Manager.UnregisterAmbientZone(AmbZone);
}

AAmbientZone GetHighestPriorityZone(UHazeListenerComponent Listener)
{
	AAmbientZone PrioZone;
	uint32 HighestPriority = 0.f;

	for(FAmbientZoneOverlap& ZoneOverlap : Listener.AmbientZoneOverlaps)
	{	
		AAmbientZone AmbZone = Cast<AAmbientZone>(ZoneOverlap.AmbientZone);		
		if(AmbZone.Priority > HighestPriority)
		{
			HighestPriority = AmbZone.Priority;
			PrioZone = AmbZone;
		}
	}
	return PrioZone;
}
