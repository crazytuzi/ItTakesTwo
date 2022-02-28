
UCLASS(Meta = (ComposeSettingsOnto = "UGroundPoundDynamicSettings"))
class UGroundPoundDynamicSettings : UHazeComposableSettings
{
	// The minimum height needed when travelling upwards to trigger able to enter groundpound.
	UPROPERTY()
	float MinHeight = 150.f;
}

namespace GroundPoundSettings
{
	const FGroundPoundEnterSettings Enter;

	const FGroundPoundFallSettings Falling;

	const FGroundPoundStandUpSettings StandUp;

	const FGroundPoundLandingSettings Landing;
}

struct FGroundPoundEnterSettings
{
	const float Duration = 0.3f;
}

struct FGroundPoundFallSettings
{
    const float FallStartSpeed = 1500.f;

	const float FallMaxSpeed = 10000.f;

	const float FallTimeToReachMaxSpeed = 1.5f;
}

struct FGroundPoundLandingSettings
{
	const float StunDuration = 0.1f;
}

struct FGroundPoundStandUpSettings
{
	// how long to wait until it activates
	const float ActivationTime = .5f;

	const float Duration = .5f;
}
