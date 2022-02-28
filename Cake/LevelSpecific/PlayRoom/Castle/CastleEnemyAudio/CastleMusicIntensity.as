import Vino.AI.Audio.MusicIntensityTeam;

namespace CastleMusicIntensity
{
	const FName TeamName = n"CastleEnemyMusicIntensityTeam";

	UFUNCTION()
	void SetInitialCastleMusicIntensity(EMusicIntensityLevel Intensity, float AmbientDelay)
	{
		UMusicIntensityTeam Team = Cast<UMusicIntensityTeam>(HazeAIBlueprintHelper::GetTeam(TeamName));
		if (Team != nullptr)
		{
			// Force team to set given intensity. Will last until team decides to set or clear intensity by itself.
			Team.SetInitialIntensity(Intensity, AmbientDelay);
		}
	}
}

