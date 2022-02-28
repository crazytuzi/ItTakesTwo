import Cake.LevelSpecific.Tree.Queen.QueenActor;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackDeathRay;

class UDeathrayCameraVolumeCustomCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		UHazeAITeam QueenTeam =HazeAIBlueprintHelper::GetTeam(n"Queen");
		TSet<AHazeActor> Members = QueenTeam.GetMembers();
		AHazeActor HazeMember;

		for (auto Member : Members)
		{
			HazeMember = Member;
		}

		AQueenActor Queen = Cast<AQueenActor>(HazeMember);

		UQueenSpecialAttackDeathRay SpecialAttack = UQueenSpecialAttackDeathRay::Get(Queen);

		return !(SpecialAttack.PlayersDoneRoundTrip.Contains(Player));
	}
}