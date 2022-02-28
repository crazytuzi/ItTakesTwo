class AHomeworkTimer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	USceneComponent TopMeshRoot;

	UPROPERTY(DefaultComponent, Attach = TopMeshRoot)
	UStaticMeshComponent TopMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartTickingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopTickingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TimeUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WindupStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WindupCompleteAudioEvent;

	UPROPERTY()
	bool bDoubleTime = false;

	bool bIsWindUpComplete = false;


	FHazeTimeLike WindupTimerTimeline;
	default WindupTimerTimeline.Duration = 1.f;

	float MaxTime = 0.f;
	float CurrentTime = 0.f;

	float WindupLerp = 0.f;
	float WindupLerpMax = 0.f;

	float SecondsMultiplier = 6.f;

	bool bShouldTickTime = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WindupTimerTimeline.BindUpdate(this, n"WindupTimerTimelineUpdate");

		if (bDoubleTime)
			SecondsMultiplier = SecondsMultiplier / 2.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickTime)
			TickTime(DeltaTime);
			
	}

	UFUNCTION()
	void SetTime(float NewTime)
	{
		MaxTime = NewTime;
		CurrentTime = MaxTime;
		WindupLerpMax = TopMesh.RelativeRotation.Yaw / ((MaxTime * SecondsMultiplier) - 1.f);
		WindupTimerTimeline.PlayFromStart();

		HazeAkComp.HazePostEvent(WindupStartAudioEvent);
	}

	UFUNCTION()
	void TickTime(float DeltaTime)
	{
		CurrentTime -= DeltaTime;
		TopMesh.SetRelativeRotation(FRotator(0.f, (CurrentTime * SecondsMultiplier), 0.f));
		if (CurrentTime <= 0.f)
		{
			StopTimer();
			CurrentTime = 0.f;
		}

		if (CurrentTime <= 0.02f)
		{
			HazeAkComp.HazePostEvent(TimeUpAudioEvent);
		}
	}

	UFUNCTION()
	void StopTimer()
	{
		bShouldTickTime = false;
		HazeAkComp.HazePostEvent(StopTickingAudioEvent);
	}

	UFUNCTION()
	void StartTimer()
	{
		bShouldTickTime = true;
		HazeAkComp.HazePostEvent(StartTickingAudioEvent);
	}

	UFUNCTION()
	void WindupTimerTimelineUpdate(float CurrentTime)
	{
		WindupLerp = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(WindupLerpMax, 1.f), CurrentTime);
		TopMesh.SetRelativeRotation(FRotator(0.f, FMath::Lerp(0.f, (MaxTime * SecondsMultiplier) - 1.f, WindupLerp), 0.f));

		if ((FMath::IsNearlyEqual(WindupLerp, 1.f, 0.05f)) && !bIsWindUpComplete)
		{
			HazeAkComp.HazePostEvent(WindupCompleteAudioEvent);
			bIsWindUpComplete = true;
		}
		else if (WindupLerp < 0.95f)
			bIsWindUpComplete = false;
	}
}