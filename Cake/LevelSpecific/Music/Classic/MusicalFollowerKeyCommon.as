import Cake.LevelSpecific.Music.Classic.MusicalFollowerKeyTeam;

void SetupMusicalFollowerKey(AHazeActor MusicalFollowerKey)
{
	MusicalFollowerKey.JoinTeam(n"MusicalKeyTeam", UMusicalFollowerKeyTeam::StaticClass());
}
