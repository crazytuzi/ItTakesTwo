import Peanuts.Spline.SplineActor;


class ACutieFleeing: AHazeCharacter
{
	UPROPERTY()
    ASplineActor SplineToFollow;
	UPROPERTY()
    ASplineActor SplineOne;
	UPROPERTY()
    ASplineActor SplineTwo;
	UPROPERTY()
    ASplineActor SplineThree;
	UPROPERTY()
    ASplineActor SplineFour;
	UPROPERTY()
    UAnimSequence TurnAnimation;
	UPROPERTY()
    UAnimSequence RunAnimation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SmoothVectorLocation;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothRotation;

	UPROPERTY()
	AActor StartLocationActor;
	UPROPERTY()
	float DesiredFollowSpeed = 300.f;
	bool bFollowingSpline = false;
	float CurrentFollowSpeed;
	FRotator CurrentRotation;
	FVector CurrentLocation;
	float LocationMulitplier = 4;
	float RotationMuliplier = 2.75;
	float DistanceAlongSpline = 0.f;

	float FoghornBarkTimer = 5.f;
	float FoghornBarkTimerTemp = 5.f;


	UPROPERTY()
	float LerpSpeed = 3.f;
	bool IsMovingReversed = false;

	int TimesSwapedSpline = 0;
	bool SplineSwapIsQued = false;
	bool SwapToSplineOne = false;
	bool SwapToSplineTwo = false;
	bool SwapToSplineThree= false;
	bool SwapToSplineFour = false;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		CurrentLocation = StartLocationActor.GetActorLocation();
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Cutie_InsideClawMachine", 1.f);
		
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bFollowingSpline)
		{
			if(HasControl())
			{
				SmoothVectorLocation.Value = GetActorLocation();
				SmoothRotation.Value = GetActorRotation();
			}
			else
			{	
				SetActorLocationAndRotation(SmoothVectorLocation.Value, SmoothRotation.Value);
			}

			FoghornBarkTimerTemp -= DeltaTime;
			if(FoghornBarkTimerTemp <= 0) 
			{
				PlayFoghornRunBark();
				FoghornBarkTimerTemp = FoghornBarkTimer;
			}

			
			if(!HasControl())
				return;


			if(SplineToFollow.Spline.GetSplineLength() <= DistanceAlongSpline && IsMovingReversed == false)
			{
				DistanceAlongSpline = 0;
				SwapFollowSpline();
			}

			if(0 >= DistanceAlongSpline && IsMovingReversed == true)
			{
				DistanceAlongSpline = SplineToFollow.Spline.GetSplineLength();
				SwapFollowSpline();
			}

			CurrentFollowSpeed = FMath::FInterpTo(CurrentFollowSpeed, DesiredFollowSpeed, DeltaTime, LerpSpeed);
			

			if(!IsMovingReversed)
			{
				DistanceAlongSpline += CurrentFollowSpeed * DeltaTime;
				FVector Loc = SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				FRotator Rot = SplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				CurrentRotation = FMath::LerpShortestPath(CurrentRotation, Rot, DeltaTime * RotationMuliplier);
				CurrentLocation = FMath::Lerp(CurrentLocation, Loc, DeltaTime * LocationMulitplier);
				SetActorLocationAndRotation(CurrentLocation, CurrentRotation);
			}
			if(IsMovingReversed)
			{
				DistanceAlongSpline -= CurrentFollowSpeed * DeltaTime;
				FVector Loc = SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				FRotator Rot = SplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, -ESplineCoordinateSpace::World);
				CurrentRotation = FMath::LerpShortestPath(CurrentRotation, Rot, DeltaTime * RotationMuliplier);
				CurrentLocation = FMath::Lerp(CurrentLocation, Loc, DeltaTime * LocationMulitplier);
				SetActorLocationAndRotation(CurrentLocation, (CurrentRotation + FRotator(0, -90,0)));
			}
		}
	}

	UFUNCTION()
	void DisableCutie()
	{
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Cutie_InsideClawMachine", 0.f);	
		
		SetActorHiddenInGame(true);
		DisableActor(nullptr);
	}

	UFUNCTION()
	void StartFollowingSpline()
	{
		if(this.HasControl())
		{
			NetStartFollowingSpline();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartFollowingSpline()
	{
		if (SplineToFollow != nullptr)
		{
			bFollowingSpline = true;
			SetActorHiddenInGame(false);
			StartRunAnimation();
		}
	}



	UFUNCTION()
	void QueSwapSpline()
	{
		if(TimesSwapedSpline == 0)
		{
			SwapToSplineTwo = true;
		}
		if(TimesSwapedSpline == 1)
		{
			SwapToSplineThree = true;
		}
		if(TimesSwapedSpline == 2)
		{
			SwapToSplineFour = true;
		}
		if(TimesSwapedSpline == 3)
		{
			SwapToSplineOne= true;
			TimesSwapedSpline = 0;
		}

		TimesSwapedSpline ++;
	}

	UFUNCTION()
	void SwapFollowSpline()
	{
		if(SwapToSplineOne == true)
		{
			SwapToSplineOne = false;
			SplineToFollow = SplineOne;
		}
		if(SwapToSplineTwo == true)
		{
			SwapToSplineTwo = false;
			SplineToFollow = SplineTwo;
		}
		if(SwapToSplineThree == true)
		{
			SwapToSplineThree = false;
			SplineToFollow = SplineThree;
		}
		if(SwapToSplineFour == true)
		{
			SwapToSplineFour = false;
			SplineToFollow = SplineFour;
		}

		if(IsMovingReversed)
		{
			DistanceAlongSpline = SplineToFollow.Spline.GetSplineLength();
		}
		if(!IsMovingReversed)
		{
			DistanceAlongSpline = 0;
		}
	}

	UFUNCTION()
	void ReverseDirection()
	{
		if(!bFollowingSpline)
			return;
		
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"StartRunAnimation");
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = TurnAnimation, bLoop = false);

		if(IsMovingReversed)
		{
			IsMovingReversed = false;
		}
		else
		{
			IsMovingReversed = true;
		}
	}
	UFUNCTION()
	void StartRunAnimation()
	{
		PlayEventAnimation(Animation = RunAnimation, bLoop = true);
	}

	UFUNCTION()
	void PlayFoghornRunBark()
	{
		SetCapabilityActionState(n"FoghornDBClawMachineRunCutie", EHazeActionState::ActiveForOneFrame);
		SetCapabilityActionState(n"FoghornDBEffortRunningCutie", EHazeActionState::ActiveForOneFrame);
	}
}

