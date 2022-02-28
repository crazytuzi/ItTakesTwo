import Cake.LevelSpecific.Music.NightClub.BassDropOMeter;

class ADjAudience : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndPosition;

	UPROPERTY(DefaultComponent)
    UBillboardComponent Bill;

	UPROPERTY()
	ABassDropOMeter BassDropOMeter;

	UPROPERTY()
	UAnimSequence ActiveAnimation;

	UPROPERTY()
	UAnimSequence PassiveAnimation;

	UPROPERTY()
	UAnimSequence WalkInAnimation;

	UPROPERTY()
	UAnimSequence WalkOutAnimation;

	UPROPERTY()
	int MyLineInTheCue = 0;
	
	UPROPERTY()
	int NumberOfAudienceMembers = 0;

	bool CurrentlyWalkingIn = false;

	bool CurrentlyWalkingOut = false;

	FHazePlaySlotAnimationParams PassiveAnim;

	FHazePlaySlotAnimationParams ActiveAnim;

	FHazePlaySlotAnimationParams WalkInAnim;

	FHazePlaySlotAnimationParams WalkOutAnim;

	bool bIsActive = false;

	float MyBassDropValue = 0.f;

	FVector StartPosition;
	
	FVector CurrentLocation;

	FVector TargetLocation;

	float TargetDanceIntensity = 0.f;

	float CurrentDanceIntensity = 0.f;

	FRotator DanceRotation = FRotator::ZeroRotator;

	FRotator WalkInRotation;
	
	FRotator WalkOutRotation;

	FRotator CurrentRotation;

	FRotator TargetRotation;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPosition = FVector::ZeroVector;
			
		PassiveAnim.Animation = PassiveAnimation;
		PassiveAnim.bLoop = true;
		PassiveAnim.StartTime = FMath::RandRange(0.f, 3.2f);

		ActiveAnim.Animation = ActiveAnimation;
		ActiveAnim.bLoop = true;

		WalkInAnim.Animation = WalkInAnimation;
		WalkInAnim.bLoop = true;
		
		WalkOutAnim.Animation = WalkOutAnimation;
		WalkOutAnim.bLoop = true;

		FVector StartPointingAtEnd = EndPosition - StartPosition;

		WalkInRotation = Math::MakeRotFromX(StartPointingAtEnd);
		WalkOutRotation = Math::MakeRotFromX(StartPointingAtEnd) + FRotator(0.f, 180.f, 0.f);
		
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentLocation = SkelMesh.GetRelativeLocation();
		CurrentRotation = SkelMesh.GetRelativeRotation();

		FRotator FinalRotation = FMath::RInterpConstantTo(CurrentRotation, TargetRotation, DeltaTime, 200.f);

		if(BassDropOMeter.BassDropOMeterProgress > MyBassDropValue)
		{
			CurrentlyWalkingOut = false;
			TargetLocation = FMath::VInterpConstantTo(CurrentLocation, EndPosition, DeltaTime, 700.f);
			TargetDanceIntensity = 500.f;
						
			SkelMesh.SetRelativeLocation(TargetLocation);
			SkelMesh.SetRelativeRotation(FinalRotation);
			
			
			if (TargetLocation == EndPosition)
				{
					SetAnimation(true);
					return;
				}

			StartWalkingInAnimation();
		}

		else
		{
			CurrentlyWalkingIn = false;
			TargetLocation = FMath::VInterpConstantTo(CurrentLocation, StartPosition, DeltaTime, 500.f);
			TargetDanceIntensity = 0.f;

			SkelMesh.SetRelativeLocation(TargetLocation);
			SkelMesh.SetRelativeRotation(FinalRotation);


			if (TargetLocation == StartPosition)
			{
				SetAnimation(false);
				return;
			}

			StartWalkingOutAnimation();
		}
			

			//Setting material intensity value
			float NewDanceIntensity = FMath::FInterpTo(CurrentDanceIntensity, TargetDanceIntensity, DeltaTime, 0.1f);
			SkelMesh.SetScalarParameterValueOnMaterialIndex(2, n"Dancing", NewDanceIntensity);
			CurrentDanceIntensity = NewDanceIntensity;

	}

	UFUNCTION()
	void SetBassDropValue()
	{
		MyBassDropValue = FMath::GetMappedRangeValueClamped(FVector2D(0.f, NumberOfAudienceMembers), FVector2D(0.f, 1.f), MyLineInTheCue);
	}

	void StartWalkingInAnimation()
	{
		if (!CurrentlyWalkingIn)
		{
			SkelMesh.PlaySlotAnimation(WalkInAnim);
			TargetRotation = WalkInRotation;
			CurrentlyWalkingIn = true;
		}
	}

	void StartWalkingOutAnimation()
	{
		if (!CurrentlyWalkingOut)
		{
			SkelMesh.PlaySlotAnimation(WalkOutAnim);
			TargetRotation = WalkOutRotation;
			CurrentlyWalkingOut = true;
		}
	}

	void SetAnimation(bool Active)
	{
		if (bIsActive && Active)
		{
			bIsActive = false;
			CurrentlyWalkingIn = false;
			SkelMesh.PlaySlotAnimation(ActiveAnim);
			TargetRotation = DanceRotation;
		}

		else if (!bIsActive && !Active)
		{
			bIsActive = true;
			CurrentlyWalkingOut = false;
			SkelMesh.PlaySlotAnimation(PassiveAnim);
		}
	}





}