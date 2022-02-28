import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSettings;

namespace MoleStealthSettings
{
	bool DelaySoundDecrease(float WantedIncreaseAmount, EMoleStealthDetectionSoundVolume SoundType)
	{
		if(SoundType == EMoleStealthDetectionSoundVolume::Null && TimeUntilDecreaseStarts <= 0)
			return false;

		if(SoundType == EMoleStealthDetectionSoundVolume::None && TimeUntilDecreaseStarts <= 0)
			return false;

		if(WantedIncreaseAmount <= 0)
			return false;

		return true;
	}
}
