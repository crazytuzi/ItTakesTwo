UCLASS(Meta = (ComposeSettingsOnto = "UCharacterJumpSettings"))
class UCharacterJumpSettings : UHazeComposableSettings
{
	// Gravity strength scale while in a jump
	UPROPERTY()
	float JumpGravityScale = 1.f;

	UPROPERTY()
	float FloorJumpImpulse = 1300.f;

	UPROPERTY()
	float AirJumpImpulse = 1620.f;

	// Wallslide
	UPROPERTY()
	FJumpImpulses WallSlideJumpUpImpulses;
	default WallSlideJumpUpImpulses.Horizontal = 250.f;
	default WallSlideJumpUpImpulses.Vertical = 1350.f;

	UPROPERTY()
	FJumpImpulses WallSlideJumpAwayImpulses;
	default WallSlideJumpAwayImpulses.Horizontal = 950.f;
	default WallSlideJumpAwayImpulses.Vertical = 1450.f;

	// Ledge Grab
	UPROPERTY()
	float LedgeGrabJumpUpImpulse = 1450.f;

	UPROPERTY()
	FJumpImpulses LedgeGrabJumpAwayImpulses;
	default LedgeGrabJumpAwayImpulses.Horizontal = 950.f;
	default LedgeGrabJumpAwayImpulses.Vertical = 1450.f;

	//Ledge Node
	UPROPERTY()
	float LedgeNodeJumpUpImpulse = 1450.f;

	UPROPERTY()
	FJumpImpulses LedgeNodeJumpAwayImpulses;
	default LedgeNodeJumpAwayImpulses.Horizontal = 950.f;
	default LedgeNodeJumpAwayImpulses.Vertical = 1450.f;

	//GroundPound
	UPROPERTY()
	float GroundPoundJumpImpulse = 2560.f;

	//LongJump
	UPROPERTY()
	FJumpImpulses LongJumpImpulses;
	default LongJumpImpulses.Horizontal = 1550.f;	
	default LongJumpImpulses.Vertical = 1300.f;

	UPROPERTY()
	float LongJumpStartGravityMultiplier = 1.f;
	
	// The duration that the player is regarded as grounded after becoming airborne
	const float GroundedGracePeriod = 0.122f;
}

struct FJumpImpulses
{
	UPROPERTY()
	float Horizontal = 0.f;

	UPROPERTY()
	float Vertical = 0.f;
}
