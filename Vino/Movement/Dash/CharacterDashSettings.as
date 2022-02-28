UCLASS(Meta = (ComposeSettingsOnto = "UCharacterDashSettings"))
class UCharacterDashSettings : UHazeComposableSettings
{
	// The initial speed of the dash
	UPROPERTY()
	float StartSpeed = 2050.f;

	// The speed of the dash at the end of the duration
	UPROPERTY()
    float EndSpeed = 1500.f;	

	// How long the dash lasts for
    const float Duration = 0.36f;

	// How long the players input can steer the direction of the dash
    const float ControlDuration = 0.065f;

	// The cooldown duration after the end of the dash before you can dash again
	const float Cooldown = 0.25f;

	// The speed of rotation during teh dash
	const float FacingDirectionRotationSpeed = 10.f;
}

UCLASS(Meta = (ComposeSettingsOnto = "UCharacterPerfectDashSettings"))
class UCharacterPerfectDashSettings : UHazeComposableSettings
{
	// The initial speed of the dash
	UPROPERTY()
	float StartSpeed = 2600.f;

	// The speed of the dash at the end of the duration
	UPROPERTY()
    float EndSpeed = 1500.f;	

	// How long the dash lasts for
    const float Duration = 0.6f;

	// The earliest you can start the perfect dash, from the end of the dash going backwards
	const float ActivationTimeFromEnd = 0.1f;

	// How late you can start the perfect dash, from the end of the dash going forwards
	const float PostDashActivationTime = 0.15f;

	// How long the players input can steer the direction of the dash
    const float ControlDuration = 0.065f;

	// The speed of rotation during teh dash
	const float FacingDirectionRotationSpeed = 10.f;
}

UCLASS(Meta = (ComposeSettingsOnto = "UCharacterAirDashSettings"))
class UCharacterAirDashSettings : UHazeComposableSettings
{
	// The initial speed of the dash
	UPROPERTY()
	float StartSpeed = 1900.f;

	// The speed of the dash at the end of the duration
	UPROPERTY()
    float EndSpeed = 1100.f;

	// Your vertical velocity speed on activation
	UPROPERTY()
	float StartUpwardsSpeed = 400.f;

	const float SpeedPow = 1.3f;

	const float GravityPow = 0.7f;

	// How long the dash lasts for
    const float Duration = 0.36f;

	// How long the players input can steer the direction of the dash
    const float ControlDuration = 0.065f;

	// The cooldown duration after the end of the dash before you can dash again
	const float Cooldown = 0.25f;

	// The speed of rotation during teh dash
	const float FacingDirectionRotationSpeed = 10.f;
}

UCLASS(Meta = (ComposeSettingsOnto = "UGroundPoundDashSettings"))
class UGroundPoundDashSettings : UHazeComposableSettings
{
	// The initial speed of the dsah
	UPROPERTY()
	float StartSpeed = 2800.f;

	// The speed at the end of the dash
	UPROPERTY()
	float EndSpeed = 1300.f;

	// How long the dash will last for
	const float Duration = 0.4f;

	// Peak rotation speed at the end of the dash
	const float MaxTurnRate = 360.f;

	// The curve of the lerp to max turn rate throughout the Duration
	const float TurnRatePow = 1.3f;
	
	// The curve of the lerp from Start to End speed throughout the duration
	const float SpeedPow = 1.3f;

	// The curve of the lerp from Start to End gravity throughout the duration
	const float GravityPow = 1.0f;

	// The vertical speed will be clamped to this value if not grounded.
	const float AirborneMaxVertical = 1000.f;
}

struct FCharacterDashSlowdownSettings
{
	// The duration of the slowdown capability
	const float Duration = 0.25f;
}

namespace DashTags
{
	const FName GroundDashing = n"GroundDashCapabilityActiveTags";
	const FName AirDashing = n"AirDashCapabilityActiveTags";
}
