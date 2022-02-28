class PullbackCarDepotDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPoseableMeshComponent BoxPoseableMesh;

	UPROPERTY(DefaultComponent, NotEditable)
    UHazeAkComponent HazeAkComp;

	UPROPERTY()
	FHazeTimeLike OpenDoorTimeline;
	default OpenDoorTimeline.Duration = 0.25f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_DepotDoorOpen_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_DepotDoorClose_AudioEvent;

	bool bShouldTickCloseDoorTimer = false;
	float CloseDoorTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenDoorTimeline.BindUpdate(this, n"OpenDoorTimelineUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickCloseDoorTimer)
		{
			CloseDoorTimer -= DeltaTime;
			if (CloseDoorTimer <= 0.f)
			{
				bShouldTickCloseDoorTimer = false;
				OpenDoorTimeline.Reverse();
				AudioDoorClosing();
			}
		}
	}

	UFUNCTION()
	void OpenDoorTimelineUpdate(float CurrentValue)
	{
		BoxPoseableMesh.SetBoneRotationByName(n"Lid1", FMath::LerpShortestPath(FRotator(0.f, -180.f, -180.f), FRotator(180.f, -180.f, -180.f), CurrentValue), EBoneSpaces::ComponentSpace);
	}

	UFUNCTION()
	void OpenDoorForDuration(float Duration)
	{
		OpenDoorTimeline.Play();
		AudioDoorOpening();
		CloseDoorTimer = Duration;
		bShouldTickCloseDoorTimer = true;
	}

	UFUNCTION()
	void AudioDoorOpening()
	{
		HazeAkComp.HazePostEvent(PBC_DepotDoorOpen_AudioEvent);
	}

	UFUNCTION()
	void AudioDoorClosing()
	{
		HazeAkComp.HazePostEvent(PBC_DepotDoorClose_AudioEvent);
	}
}