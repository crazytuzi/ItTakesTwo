
// SETTINGS
namespace MoleStealthSettings
{
	// The max value of the volume meter
	const float MaxVolume = 100.f;
	
	// How long time until the meter starts decreasing
	const float TimeUntilDecreaseStarts = 1.55f;

	// How fast the meter decreases
	const float DecreaseSpeed = 20.f;


	/* When max volume is reached,
	 * This is the second life max volume.
	*/
	const float MaxVolumeSecondLife = 65.f;

	// How long time until the meter starts decreasing
	const float TimeUntilDecreaseStartsSecondLife = 1.75;
}

// ENUM
enum EMoleStealthDetectionSoundVolume
{
	Null,
	None,
	Low,
	Normal,
	High,
	InstantDeath
};
