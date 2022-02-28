import Peanuts.Audio.AudioStatics;	
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAudio.CastleEnemyVOEffortsManager;
	
float GetObjectScreenPos(AHazeActor Actor)
{
	AHazePlayerCharacter Player = SceneView::GetFullScreenPlayer();
	FVector EnemyPosition = Actor.GetActorLocation();
	
	FVector2D ScreenPos;
	SceneView::ProjectWorldToScreenPosition(Player, EnemyPosition, ScreenPos);		

	const float NormalizedAngleRtpc = HazeAudio::NormalizeRTPC(ScreenPos.X, 0.f, 1.f, -1.f, 1.f);
	return NormalizedAngleRtpc;
}

UCastleEnemyVOEffortsManager GetCastleEnemyVOManager()
{
	UCastleEnemyVOEffortsManager VoManager = UCastleEnemyVOEffortsManager::Get(Game::GetMay());
	return VoManager;
}

