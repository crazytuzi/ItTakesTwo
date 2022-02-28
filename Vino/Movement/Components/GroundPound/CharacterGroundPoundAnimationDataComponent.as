enum EGroundPoundJumpType
{
	None,
	Low,
	High
};

class UCharacterGroundPoundAnimationDataComponent : UActorComponent
{
	UPROPERTY()
	bool bIsFalling = false;

	UPROPERTY()
	bool bIsLanding = false;

	UPROPERTY()
	bool bIsStandingUp = false;

	UPROPERTY()
	bool bIsJumping = false;

	UPROPERTY()
	bool bIsTotemHead = false;

	UPROPERTY()
	bool bIsTotemBody = false;

	UPROPERTY()
	EGroundPoundJumpType JumpType = EGroundPoundJumpType::None;

	void Reset()
	{
		bIsFalling = false;
		bIsLanding = false;
		bIsStandingUp = false;
		bIsJumping = false;
		bIsTotemHead = false;
		bIsTotemBody = false;

		JumpType = EGroundPoundJumpType::None;
	}
}