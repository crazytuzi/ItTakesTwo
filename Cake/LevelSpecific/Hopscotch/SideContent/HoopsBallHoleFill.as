class AHoopsBallHoleFill : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TopMeshRoot;

	UPROPERTY(DefaultComponent, Attach = TopMeshRoot)
	UStaticMeshComponent TopHoleFillMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BottomMeshRoot;

	UPROPERTY(DefaultComponent, Attach = BottomMeshRoot)
	UStaticMeshComponent BottomHoleFillMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OpenAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CloseAudioEvent;

	float TopFillTimerDuration = 0.5f;
	float TopFillTimer = 0.f;
	bool bShouldTickTopFillTimer = false;
	
	float BottomFillTimerDuration = 0.75f;
	float BottomFillTimer = 0.f;
	bool bShouldTickBottomFillTimer = false;

	FVector TopStartLoc = FVector::ZeroVector;
	FVector TopTargetLoc = FVector(-140.f, 0.f, 0.f);
	FVector BottomStartLoc = FVector(0.f, 0.f, -170.f);
	FVector BottomTargetLoc = FVector::ZeroVector;

	bool bShouldOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldTickTopFillTimer)
		{
			if (bShouldOpen)
				TopFillTimer += DeltaTime;
			else
				TopFillTimer -= DeltaTime;
			
			TopMeshRoot.SetRelativeLocation(FMath::Lerp(TopStartLoc, TopTargetLoc, TopFillTimer/TopFillTimerDuration));
			if (bShouldOpen && TopFillTimer >= TopFillTimerDuration)
			{
				TopMeshRoot.SetRelativeLocation(TopTargetLoc);
				bShouldTickTopFillTimer = false;
				bShouldTickBottomFillTimer = true;
			}
			else if (!bShouldOpen && TopFillTimer <= 0.f)
			{
				TopMeshRoot.SetRelativeLocation(TopStartLoc);
				bShouldTickTopFillTimer = false;
			}
		}

		if (bShouldTickBottomFillTimer)
		{
			if (bShouldOpen)
				BottomFillTimer += DeltaTime;
			else
				BottomFillTimer -= DeltaTime;

			BottomMeshRoot.SetRelativeLocation(FMath::Lerp(BottomStartLoc, BottomTargetLoc, BottomFillTimer/BottomFillTimerDuration));
			if (bShouldOpen && BottomFillTimer >= BottomFillTimerDuration)
			{
				BottomMeshRoot.SetRelativeLocation(BottomTargetLoc);
				bShouldTickBottomFillTimer = false;
			}
			else if(!bShouldOpen && BottomFillTimer <= 0.f)
			{
				BottomMeshRoot.SetRelativeLocation(BottomStartLoc);
				bShouldTickBottomFillTimer = false;
				bShouldTickTopFillTimer = true;
			}
		}
	}

	void SetHoleFillOpen(bool bOpen)
	{
		if (bOpen)
		{
			TopFillTimer = 0.f;
			BottomFillTimer = 0.f;
			bShouldTickTopFillTimer = true;
			bShouldOpen = true;
			AudioHoleFillOpened(true);
		} else
		{
			TopFillTimer = TopFillTimerDuration;
			BottomFillTimer = BottomFillTimerDuration;
			bShouldTickBottomFillTimer = true;
			bShouldOpen = false;
			AudioHoleFillOpened(false);
		}
	}

	UFUNCTION()
	void AudioHoleFillOpened(bool bOpen)
	{
		if (bOpen)
		{
			HazeAkComponent.HazePostEvent(OpenAudioEvent);
		} 
		else 
		{
			HazeAkComponent.HazePostEvent(CloseAudioEvent);
		}
	}
}