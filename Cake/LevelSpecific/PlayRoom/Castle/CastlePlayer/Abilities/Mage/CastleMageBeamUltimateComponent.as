class UCastleMageBeamUltimateComponent : UActorComponent
{	
	UPROPERTY()
    float Duration = 5.0f;

    UPROPERTY()
    float DurationCurrent = 0.f;

	FVector BeamEnd;
	float BeamLength;
	bool bLastHitBlocking = false;

	bool bActivated = false;
}