import Cake.LevelSpecific.Tree.Approach.SideContent.BirdMom_AnimNotify_Happy;
event void FOnAllEggsDelivered();
class ABirdMom : AHazeCharacter
{
	UPROPERTY()
	bool bHappy = false;
	UPROPERTY()
	bool bAllEggs = false;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayNestlingsLoopAudioEvent;

	UPROPERTY()
	int EggAmountDelivered = 0;
	bool bHappyAnimationTriggeredManually = false;
	
	UPROPERTY()
	FOnAllEggsDelivered OnAllEggsDelivered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeAnimNotifyDelegate BirdMomHappyFinishedDelegate;
		BirdMomHappyFinishedDelegate.BindUFunction(this, n"HappyAnimationFinished");
		BindAnimNotifyDelegate(UAnimNotify_BirdMomHappyFinished::StaticClass(), BirdMomHappyFinishedDelegate);
	}

	UFUNCTION()
	void EggDelivered()
	{
		EggAmountDelivered ++;
		bHappy = true;
	}
	UFUNCTION()
	void ManualAddEgg()
	{
		EggAmountDelivered ++;
	}

	UFUNCTION()
	void HappyAnimationFinished(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		if(bHappyAnimationTriggeredManually)
			return;
			
		CheckIfAllEggsDelivered();
		bHappy = false;
	}
	UFUNCTION()
	void ManualPlayHappyAnimation()
	{
		bHappy = true;
		bAllEggs = true;
		bHappyAnimationTriggeredManually = true;
	}

	UFUNCTION()
	void CheckIfAllEggsDelivered()
	{
		if(EggAmountDelivered >= 3)
		{
			bAllEggs = true;
			OnAllEggsDelivered.Broadcast();
			HazeAkComp.HazePostEvent(PlayNestlingsLoopAudioEvent);
		}
	}
}

