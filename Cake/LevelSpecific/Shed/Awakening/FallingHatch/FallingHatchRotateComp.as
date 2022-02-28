class UFallingHatchRotatingComp : USceneComponent
{

	UPROPERTY()
	FHazeTimeLike SweyingTimeLike;

	UPROPERTY()
	FHazeTimeLike AttachOnceTimeLike;

	float StartRoll;
	bool bShouldStartLoop = false;
	
		UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRoll = Owner.ActorRotation.Pitch;
		SweyingTimeLike.BindUpdate(this, n"TimeLikeTick");
		AttachOnceTimeLike.BindUpdate(this, n"TimeLikeTick");
		AttachOnceTimeLike.BindFinished(this, n"FirstSweyDone");
	}

	UFUNCTION()
	void StartWiggle()
	{
		if(!bShouldStartLoop)
		{
			AttachOnceTimeLike.PlayFromStart();
		}

		bShouldStartLoop = true;
	}

	UFUNCTION()
	void FirstSweyDone()
	{
		if (bShouldStartLoop)
		{
			SweyingTimeLike.bLoop = true;
			SweyingTimeLike.PlayFromStart();
		}
	}

	UFUNCTION()
	void TimelikeTick(float Value)
	{
		FRotator Rotation = Owner.ActorRotation;
		Rotation.Pitch = StartRoll - Value;
		Owner.SetActorRotation(Rotation);
	}

	UFUNCTION()
	void ResetWiggle()
	{
		SweyingTimeLike.Stop();
		AttachOnceTimeLike.Stop();
		FRotator Rotation = Owner.ActorRotation;
		Rotation.Pitch = StartRoll;
		Owner.SetActorRotation(Rotation);
		bShouldStartLoop = false;
	}
}