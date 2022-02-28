class AFlippingBoardgamePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BoardFlipUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BoardFlipDownAudioEvent;

	UPROPERTY()
	FHazeTimeLike FlipTimeline;
	default FlipTimeline.Duration = 0.15f;
	
	FRotator InitialRotation;
	FRotator TargetRotation;

	UPROPERTY()
	bool bStartFlipped = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlipTimeline.BindUpdate(this, n"FlipTimelineUpdate");

		InitialRotation = FRotator::ZeroRotator;
		TargetRotation = FRotator(90.f, 0.f, 0.f);

		if (bStartFlipped)
			MeshRoot.SetRelativeRotation(TargetRotation);
	}

	UFUNCTION()
	void FlipTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(QuatLerp(InitialRotation, TargetRotation, CurrentValue));
	}

	UFUNCTION()
	void FlipPlatform()
	{
		FlipTimeline.Play();
		UHazeAkComponent::HazePostEventFireForget(BoardFlipUpAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void ReversePlatform()
	{
		FlipTimeline.Reverse();
		UHazeAkComponent::HazePostEventFireForget(BoardFlipDownAudioEvent, this.GetActorTransform());
	}
	   
	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}