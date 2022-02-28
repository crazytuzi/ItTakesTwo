class UPlayerMagnetBoostAnimationDataComponent : UActorComponent
{
	UPROPERTY()
	bool bIsWallMagnet = false;

	UPROPERTY()
	bool bIsJumping = false;

	void Reset()
	{
		bIsWallMagnet = false;
		bIsJumping = false;
	}
}