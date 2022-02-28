class UHeadbuttingDinoAnimationDataComponent: UActorComponent
{
	UPROPERTY()
	bool bIsHeadbutting  = false;

	UPROPERTY()
	bool bIsPlayingFailedHeadbutt  = false;

	UPROPERTY()
	bool bIsGrounded = true;

	UPROPERTY()
	bool bEnteredDino = false;

	UPROPERTY()
	float ForwardSpeedAlpha  = 0;
}
