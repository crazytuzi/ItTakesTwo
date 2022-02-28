import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophonesAudioManager;

UMurderMicrophonesAudioManager GetMurderMicAudioManager()
{
	return UMurderMicrophonesAudioManager::GetOrCreate(Game::GetMay());
}
