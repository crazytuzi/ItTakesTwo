class UPlayerMagnetLaunchAnimationDataComponent : UActorComponent
{
	UPROPERTY()
	bool bIsLaunching = false;

	UPROPERTY()
	bool bIsEnteringPerch = false;

	UPROPERTY()
	bool bIsEnteringGroundPerchWithNoFlight = false;

	UPROPERTY()
	bool bIsPerching = false;

	UPROPERTY()
	bool bIsJumpingOff = false;

	UPROPERTY()
	bool bPerchIsCeiling = false;

	UPROPERTY()
	bool bPerchIsGround = false;

	UPROPERTY()
	bool bBothPlayersColliding = false;

	void Reset()
	{
		bIsLaunching = false;
		bIsEnteringPerch = false;
		bIsEnteringGroundPerchWithNoFlight = false;
		bIsPerching = false;
		bIsJumpingOff = false;
		bPerchIsCeiling = false;
		bPerchIsGround = false;
		bBothPlayersColliding = false;
	}
}