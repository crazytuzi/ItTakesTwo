import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonsterSpline;

enum EMotherSnakeAnimState
{
	Bite,
	Closed,
	FullOpen,
	HalfOpen,
	Toungue
}

event void FMicrophoneMonsterSignature();

class AMicrophoneMonster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SnakeHeadMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase HeadMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;
	default SplineComp.AutoTangents = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ScreamStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ScreamStopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ScreamAppearEvent;

	// Called whenever the microphone monster enters the associated spline regions.
	UPROPERTY()
	FMicrophoneMonsterSignature OnEnteredExitLane;

	UPROPERTY()
	TArray<AMicrophoneMonsterSpline> SplineArray;

	UPROPERTY()
	UAnimSequence Bite;

	UPROPERTY()
	UAnimSequence Closed;

	UPROPERTY()
	UAnimSequence FullOpen;

	UPROPERTY()
	UAnimSequence HalfOpen;

	UPROPERTY()
	UAnimSequence Toungue;

	UPROPERTY()
	UMaterialInstance CableMat;

	bool bShouldTickAnimDuration = false;
	float CurrentAnimDuration = 0.f;
	
	AMicrophoneMonsterSpline CurrentSpline;
	int CurrentSplineIndex = 0;
	bool bShouldBob = true;
	bool bIsKilled = false;
	TArray<UHazeCableComponent> CableArray;
	bool bStartedMovingOnSpline = false;
	FVector LastLocation;

	private float LastDistance = 0.0f;

	UPROPERTY()
	bool bEndOfCurrentSpline = false;
	bool bPreEndOfCurrentSpline = false;

	float Time;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayNormalAnimState();
	}

	UFUNCTION()
	void StartSplineMovement()
	{
		bStartedMovingOnSpline = true;
		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		if (bIsKilled)
			return;

		if (bShouldTickAnimDuration)
		{
			CurrentAnimDuration -= DeltaTime;
			if (CurrentAnimDuration <= 0.f)
			{
				bShouldTickAnimDuration = false;
				PlayNormalAnimState();
			}
		}
		
		if (bShouldBob)
		{
			Time += DeltaTime * 2;		
			MeshRoot.SetRelativeLocation(FMath::Lerp(FVector(0.f, 0.f, 0.f), FVector(0.f, 0.f, 25.f), FMath::Sin(Time)));
			MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator(-2.5f, 0.f, -0.5f), FRotator(2.5f, 0.f, 0.5f), FMath::Sin(Time)));
		}

		if (CurrentSpline == nullptr || !bStartedMovingOnSpline)
			return;
		
		
		FVector CurrentLocation = HeadMesh.GetWorldLocation();
		float HeadVelo = (CurrentLocation - LastLocation).Size();

		float HeadVeloNorm = HazeAudio::NormalizeRTPC01(HeadVelo, 5.f , 100.f);

		HazeAkComp.SetRTPCValue("Rtpc_Characters_Bosses_MicrophoneMonster_Velocity", HeadVeloNorm);
		//Print("HeadVelo: " + HeadVeloNorm);

		LastLocation = CurrentLocation;

		FTransform NewTransform = CurrentSpline.MovementOnSpline();
		FVector InterpLoc = FMath::VInterpTo(ActorLocation, NewTransform.Location, DeltaTime, 1.f);
		FRotator InterRot = FMath::RInterpTo(ActorRotation, NewTransform.Rotation.Rotator(), DeltaTime, 4.f);
		SetActorLocation(NewTransform.Location);
		SetActorRotation(NewTransform.Rotator());

		if (CurrentSpline != nullptr)
		{
			bEndOfCurrentSpline = CurrentSpline.IsOnEndOfSpline();
			CurrentSpline.SplineRegionContainer.UpdateRegionActivity(this, CurrentSpline.Distance, LastDistance, true);
		}
			

		LastDistance = CurrentSpline.Distance;
	}

	UFUNCTION()
	void SetNewMicrophoneAnimationState(EMotherSnakeAnimState State, float Duration)
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.bLoop = true;
		UAkAudioEvent WantedEvent;

		switch (State)
		{
			case EMotherSnakeAnimState::Bite:
				AnimParams.Animation = Bite;
				WantedEvent = ScreamStopEvent;
				break;
			
			case EMotherSnakeAnimState::Closed:
				AnimParams.Animation = Closed;
				WantedEvent = ScreamStopEvent;
				break;

			case EMotherSnakeAnimState::FullOpen:
				AnimParams.Animation = FullOpen;
				WantedEvent = ScreamStartEvent;
				break;

			case EMotherSnakeAnimState::HalfOpen:
				AnimParams.Animation = HalfOpen;
				WantedEvent = ScreamStartEvent;
				break;

			case EMotherSnakeAnimState::Toungue:
				AnimParams.Animation = Toungue;
				WantedEvent = ScreamStopEvent;
				break;
		}


		HeadMesh.PlaySlotAnimation(AnimParams);
		HazeAkComp.HazePostEvent(WantedEvent);
		CurrentAnimDuration = Duration;
		bShouldTickAnimDuration = true;
	}

	UFUNCTION()
	void PlayNormalAnimState()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.bLoop = true;
		AnimParams.Animation = Closed;
		HeadMesh.PlaySlotAnimation(AnimParams);
		HazeAkComp.HazePostEvent(ScreamStopEvent);
	}

	UFUNCTION()
	void SetMonsterKilled()
	{
		bIsKilled = true;
		if(CurrentSpline != nullptr)
			CurrentSpline.StopSplineAudio();
	}

	void SetCableForce()
	{
		for (UHazeCableComponent Cable : CableArray)
		{
			FVector NewCableForce = MeshRoot.GetForwardVector() * -1.f;
			NewCableForce *= 40000.f;
			Cable.CableForce = NewCableForce;
		}
	}

	//UFUNCTION()
	//void ChangeSpline()
	//{	
		//CurrentSplineIndex++;
		//CurrentSpline = SplineArray[CurrentSplineIndex];
		//StartSplineMovement();
	//}

	UFUNCTION()
	void ActivateMonsterSpline(AMicrophoneMonsterSpline SplineToActivate)
	{
		bPreEndOfCurrentSpline = false;
		if(CurrentSpline != nullptr)
		{
			CurrentSpline.StopSplineAudio();
			CurrentSpline.SplineRegionContainer.ActorLeftSpline(this, ERegionExitReason::ActorExitedSpline);
		}
			

		TeleportActor(SplineToActivate.GetActorLocation(), SplineToActivate.GetActorRotation());

		CurrentSpline = SplineToActivate;
		CurrentSpline.StartMoveOnSpline();
		CurrentSpline.StartSplineAudio();
		HazeAkComp.HazePostEvent(ScreamAppearEvent);

		StartSplineMovement();
		CurrentSpline.SplineRegionContainer.ActorEnteredSpline(this);
	}

	void EnterExitLane()
	{
		OnEnteredExitLane.Broadcast();
		bPreEndOfCurrentSpline = true;
	}

	UFUNCTION()
	void StopBobbing()
	{
		bShouldBob = false;
	}
}