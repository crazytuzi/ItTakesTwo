
class ADancingFishTrophy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent FishMeshComp;
	UPROPERTY(DefaultComponent, Attach = FishMeshComp)	
	UHazeSkeletalMeshComponentBase FishMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartSingingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSingingAudioEvent;

	bool bFishActive = false;
	UPROPERTY()
	float AutoDisableTimer = 37.f;
	float AutoDisableTimerTemp;

	UPROPERTY()
	UAnimSequence FishAnim;
	UPROPERTY()
	UAnimSequence FishAnimIdle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = FishAnimIdle, bLoop = false, BlendTime = 0.2f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bFishActive)
		{
			AutoDisableTimerTemp -= DeltaSeconds;
			if(AutoDisableTimerTemp <0)
			{
				if(HasControl())
				{
					ButtonAutoDisable();
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void ButtonAutoDisable()
	{
		ButtonPressed();
	}

	UFUNCTION()
	void ButtonPressed()
	{
		if(bFishActive == false)
		{
			AutoDisableTimerTemp = AutoDisableTimer;
			bFishActive = true;

			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = FishAnim, bLoop = false, BlendTime = 0.2f);
			HazeAkComp.HazePostEvent(StartSingingAudioEvent);
		}
		else if(bFishActive == true)
		{
			bFishActive = false;
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = FishAnimIdle,  bLoop = false, BlendTime = 0.2f);
			HazeAkComp.HazePostEvent(StopSingingAudioEvent);
		}
	}
}

