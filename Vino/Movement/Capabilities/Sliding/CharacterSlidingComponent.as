class UCharacterSlidingComponent : UActorComponent
{
	UPROPERTY()
	UCurveFloat SlideSpeedCurve;

	UPROPERTY()
	UAkAudioEvent AssSlideStopEvent;

	UPROPERTY()
	FVector2D BlendSpaceValues = FVector2D(0.f, 0.f);

	UPROPERTY()
	FRotator DesiredMeshRotation = FRotator::ZeroRotator;

	UPROPERTY()
	bool bIsSliding = false;

	bool bForcedSlideInput = false;
	
	FVector GroundPoundSlidableVelocity;

	int SlidingVolumeCount = 0;

	UPROPERTY()
	FVector SlopeNormal;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem SlidingEffectTrail;

	UFUNCTION()
	void EnteredSlidingVolume()
	{
		SlidingVolumeCount += 1;
	}

	UFUNCTION()
	void LeftSlidingVolume()
	{
		SlidingVolumeCount -= 1;
	}
}