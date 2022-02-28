import Cake.LevelSpecific.Music.NightClub.Capabilities.DJStationBaseCapability;
import Cake.LevelSpecific.Music.NightClub.DJStandPendelum;

class UDJStationPendulumCapability : UDJStationBaseCapability
{
	default TargetDJStandType = EDJStandType::Pendelum;

	UAnimSequence GetAnimation(AHazePlayerCharacter Player) const
	{
		return DJStationComp.GetRandomPendulumAnim(Player);
	}

	bool ShouldLoopAnimation() const override
	{
		return false;
	}
}
