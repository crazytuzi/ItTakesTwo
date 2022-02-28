class AHopscotchNumberPillarPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformRetractAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformResettAudioEvent;

	UPROPERTY()
	FHazeTimeLike MovePlatformTimeline;
	default MovePlatformTimeline.Duration = 1.f;

	FVector StartingLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, -1300.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformTimeline.BindUpdate(this, n"MovePlatformTimelineUpdate");
	}

	UFUNCTION()
	void MovePlatform(bool bForward)
	{
		if (bForward)
		{
			UHazeAkComponent::HazePostEventFireForget(PlatformRetractAudioEvent, this.GetActorTransform());
			MovePlatformTimeline.SetPlayRate(1.f);
			MovePlatformTimeline.PlayWithAcceleration(2.f);		
		}
		else 
		{
			UHazeAkComponent::HazePostEventFireForget(PlatformResettAudioEvent, this.GetActorTransform());
			MovePlatformTimeline.SetPlayRate(1.f/0.25f);
			MovePlatformTimeline.Reverse();	
		}
	}

	UFUNCTION()
	void MovePlatformTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartingLoc, TargetLoc, CurrentValue));
	}
}