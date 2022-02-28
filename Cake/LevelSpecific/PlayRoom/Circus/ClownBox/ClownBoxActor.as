import Rice.Positions.GetClosestPlayer;

class ClownBoxActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float TimeHeldState = 0;
	bool bIsPoppedUp;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY()
	UAnimSequence PopupAnimation;

	UPROPERTY()
	UAnimSequence PopDown;

	UPROPERTY()
	UAnimSequence MH;

	UPROPERTY()
	bool bIsDisabled = true;

	bool GetIsPlayerClose() property
	{
		FVector ClosestPlayerLocation = GetClosestPlayer(ActorLocation).ActorLocation;
		FVector ClosestPlayerDir = ClosestPlayerLocation - ActorLocation;
		float DotToClosestPlayer = ClosestPlayerDir.GetSafeNormal().DotProduct(ActorForwardVector);

		if (ClosestPlayerLocation.Distance(ActorLocation) < 1500 && DotToClosestPlayer > 0.75f)
		{
			return true;
		}
		else
		{
			return false;
		}
	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = PopDown;
		Params.StartTime = PopDown.PlayLength;
		Params.bPauseAtEnd = true;
		Params.bLoop = false;
		Params.BlendTime = 0.2f;

		SkelMesh.PlaySlotAnimation(Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Commented out because the error for unreachable code was annoying
		
		// return; 
				
		// if (bIsDisabled)
		// 	return;

		// if (TimeHeldState > 1.5f)
		// {
		// 	if (bIsPoppedUp && !IsPlayerClose)
		// 	{
		// 		FHazePlaySlotAnimationParams Params;
		// 		Params.Animation = PopDown;
		// 		Params.bPauseAtEnd = true;
		// 		Params.bLoop = false;
		// 		Params.BlendTime = 0.2f;

		// 		SkelMesh.PlaySlotAnimation(Params);
				
		// 		bIsPoppedUp = false;
		// 		TimeHeldState = 0;
		// 	}
			
		// 	if (!bIsPoppedUp && IsPlayerClose)
		// 	{
		// 		FHazePlaySlotAnimationParams Params;
		// 		Params.Animation = PopupAnimation;
		// 		Params.bPauseAtEnd = false;
		// 		Params.bLoop = false;
		// 		Params.BlendTime = 0.2f;
		// 		FHazeAnimationDelegate BlendInDelegate;
		// 		FHazeAnimationDelegate BlendOutDelegate;
		// 		BlendOutDelegate.BindUFunction(this, n"RunMH");
				
		// 		SkelMesh.PlaySlotAnimation(BlendInDelegate, BlendOutDelegate, Params);

		// 		bIsPoppedUp = true;
		// 		TimeHeldState = 0;
		// 	}
		// }

		// TimeHeldState += DeltaTime;
	}

	UFUNCTION()
	void RunMH()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = MH;
		Params.bPauseAtEnd = true;
		Params.bLoop = true;
		Params.BlendTime = 0.2f;

		SkelMesh.PlaySlotAnimation(Params);
	}
}