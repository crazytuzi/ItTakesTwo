class ASnailRaceMushroomActor : AHazeActor
{
	float WaitOnEnd;
	bool bIsStopped;

	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	// This is managed from the EnableFunction
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bDisabledAtStart = true;

	UPROPERTY()
	FHazeTimeLike Timelike;

	UPROPERTY(Meta = (MakeEditWidget))
	FTransform MoveToLocation;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartMoveAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopMoveAudioEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimer(this, n"StartLooping", 1, false);

		Timelike.BindUpdate(this, n"OnTimelikeUpdate");
	}

	UFUNCTION()
	void OnTimelikeUpdate(float value)
	{
		FVector Relativelocation = FVector::ZeroVector;
		Relativelocation = FMath::Lerp(FVector::ZeroVector, MoveToLocation.Location, value);
		Mesh.SetRelativeLocation(Relativelocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		WiggleUpdate(DeltaTime);
	}

	void WiggleUpdate(float Deltatime)
	{
		float Time = Time::GameTimeSeconds;

		FRotator RelativeRotation = FRotator::ZeroRotator;
		RelativeRotation.Yaw = Deltatime * 300;
		Mesh.AddRelativeRotation(RelativeRotation);
	}

	UFUNCTION(NetFunction)
	void NetStopMushroom()
	{
		Timelike.Stop();
		System::SetTimer(this, n"ResumeTimelike", 3, false);
	}

	UFUNCTION()
	void ResumeTimelike()
	{
		Timelike.Play();
	}

	UFUNCTION()
	void StartLooping()
	{
		Timelike.PlayFromStart();
	}

	UFUNCTION()
	void StopLooping()
	{
		Timelike.Stop();
	}
}