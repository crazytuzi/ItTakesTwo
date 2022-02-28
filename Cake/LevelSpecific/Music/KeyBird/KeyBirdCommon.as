import Cake.LevelSpecific.Music.KeyBird.KeyBirdTeam;
import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdCombatArea;

namespace KeyBirdCommon
{

void SetupKeyBird(AHazeActor KeyBird)
{
	KeyBird.JoinTeam(n"KeyBirdTeam", UKeyBirdTeam::StaticClass());
}

bool IsPlayerValidTarget(AHazePlayerCharacter PlayerTarget, AKeyBirdCombatArea CombatArea = nullptr)
{
	if(PlayerTarget == nullptr)
		return false;

	if(PlayerTarget.IsAnyCapabilityActive(n"EventAnimation"))
		return false;

	UMusicKeyComponent KeyComp = UMusicKeyComponent::Get(PlayerTarget);

	if(KeyComp == nullptr)
		return false;

	if(!KeyComp.HasKey())
		return false;

	if(CombatArea != nullptr && !CombatArea.IsInsideCombatArea(PlayerTarget.ActorCenterLocation))
		return false;

	return true;
}

}
