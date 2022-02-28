import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossEventBase;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossClockFace;
import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.SwingingPendulumEvent.ClockworkLastBossSwingingPendulumEventCamera;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.SwingingPendulumEvent.ClockworkLastBossSmasher;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.SwingingPendulumEvent.ClockworkLastBossPendulum;
import Cake.LevelSpecific.Clockwork.VOBanks.ClockworkClockTowerUpperVOBank;

event void FOnPendulumAngerClock();
event void FOnPendulumStartToFall();

// Describes the sequence of pendulums that hit 
enum EClockworkPendulumPhase
{
	None,
	DestroyOuterRing,
	DestroyInnerRing,
};

struct FClockworkPendulumSequence
{
	TArray<FClockworkPendulumSwing> Sequence;

	FClockworkPendulumSequence()
	{
		Sequence.Add(FClockworkPendulumSwing( 3 ));
		Sequence.Add(FClockworkPendulumSwing( 1, 7 ));
		Sequence.Add(FClockworkPendulumSwing( 2, 4, 8 ));
		Sequence.Add(FClockworkPendulumSwing( 1, 5, 8 ));
		Sequence.Add(FClockworkPendulumSwing(EClockworkPendulumPhase::DestroyOuterRing));
		Sequence.Add(FClockworkPendulumSwing( 2, 5, 6 ));
		Sequence.Add(FClockworkPendulumSwing( 2, 3, 4, 7 ));
		Sequence.Add(FClockworkPendulumSwing( 3, 4, 7, 8 ));
		Sequence.Add(FClockworkPendulumSwing( 2, 3, 4, 5 ));
		Sequence.Add(FClockworkPendulumSwing(EClockworkPendulumPhase::DestroyInnerRing));
	}
};

class AClockworkLastBossSwingingPendulumEvent : AClockworkLastBossEventBase
{
	UPROPERTY()
	AClockworkLastBossClockFace ClockFace;

	UPROPERTY()
	AClockworkLastBossSwingingPendulumEventCamera EventCamera01;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> HandycamShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PendulumSwingShake;

	UPROPERTY()
	ACheckpoint RespawnCheckpoint;

	UPROPERTY()
	UForceFeedbackEffect PendulumFeedback;

	UPROPERTY()
	FHazeTimeLike PendulumCamShakeTimeline;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PendulumSwingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PendulumFallOuterEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PendulumFallInnerEvent;

	UPROPERTY()
	FOnPendulumAngerClock OnPendulumAngerClock; 

	UPROPERTY()
	FOnPendulumStartToFall OnPendulumStartToFall; 

	UPROPERTY()
	UClockworkClockTowerUpperVOBank VoBank;

	TArray<AClockworkLastBossPendulum> PendulumArray;
	TArray<AClockworkLastBossSmasher> SmasherArray;

	float PendulumSwingTimer;
	float PendulumSwingTimerDuration = 2.3f;

	float AngerClockTimer = 1.8f;
	float SetInitialCameraTimer = 4.5f;
	float SmashTimer = 0.f;

	int SmashAmount = 0;
	float SmasherDelay = 0.f;

	bool bCameraHasBeenTurned = true;
	bool bShouldTickPendulumTimer = false;
	bool bEventIsActive = false;
	bool bClockFaceAngered = false;
	bool bDoneInitialCameraSwitch = false;
	bool bSmashTimerActive = false;
	bool bSmasherReadyToSpawn = false;

	FClockworkPendulumSequence Sequence;
	int PendulumSequenceIndex = 0;

	bool bArePendulumsReversed = false;
	bool bFacingReversePendulums = false;

	int SmashIndex = 1;

	FHazeTimeLike TurnCameraTimeline;
	default TurnCameraTimeline.Duration = 0.8f;

	FRotator CamStartRot;
	FRotator CamTargetRot;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GetAllActorsOfClass(PendulumArray);
		GetAllActorsOfClass(SmasherArray);

		SmasherArray = SortSmasherArray(SmasherArray);

		TurnCameraTimeline.BindUpdate(this, n"TurnCameraTimelineUpdate");
		PendulumCamShakeTimeline.BindUpdate(this, n"PendulumCamShakeTimelineUpdate");

		for (AClockworkLastBossPendulum Pendulum : PendulumArray)
		{
			Pendulum.PendulumLeftPlatform.AddUFunction(this, n"PendulumLeftPlatform");
		}

		CamStartRot = EventCamera01.GetActorRotation();
		CamTargetRot = CamStartRot + FRotator(0.f, 180.f, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (!bEventIsActive)
			return;
		
		AngerClockTimer -= DeltaTime;
		if (AngerClockTimer <= 0.f && !bClockFaceAngered)
		{
			bClockFaceAngered = true;
			AngerClockFace();
			SetPendulumTimerEnabled(true);
			OnPendulumAngerClock.Broadcast();
		}

		SetInitialCameraTimer -= DeltaTime;
		if (SetInitialCameraTimer <= 0.f && !bDoneInitialCameraSwitch)
		{
			bDoneInitialCameraSwitch = true;
			SetCamera(EventCamera01);
			Game::GetCody().PlayCameraShake(HandycamShake);
		}

		if (bSmashTimerActive)
			{
				SmashTimer -= DeltaTime;

				if (SmashTimer <= 0.f)
				{
					bSmasherReadyToSpawn = true;
					bSmashTimerActive = false;
					SpawnSmashers(SmashAmount, SmasherDelay);
				}
			}

		if (!bShouldTickPendulumTimer)
			return;

		PendulumSwingTimer += DeltaTime;
		if (PendulumSwingTimer >= PendulumSwingTimerDuration)
		{
			ProgressPendulumSequence();
		}
	}

	void ProgressPendulumSequence()
	{
		OnPendulumStartToFall.Broadcast();

		const FClockworkPendulumSwing& Swing = Sequence.Sequence[PendulumSequenceIndex];
		PendulumSequenceIndex += 1;

		if (Swing.Phase == EClockworkPendulumPhase::DestroyOuterRing)
		{
			SetPendulumTimerEnabled(false);

			TurnCamera(90.f, -40.f);
			SpawnSmashers(16, 2.f);

			UHazeAkComponent::HazePostEventFireForget(PendulumFallOuterEvent, GetActorTransform());
			System::SetTimer(this, n"PlayOuterRingVO", 5.f, false);
			//PrintScaled("DestroyOuter", 2.f, FLinearColor::Black, 2.f);
		}
		else if (Swing.Phase == EClockworkPendulumPhase::DestroyInnerRing)
		{
			SetPendulumTimerEnabled(false);
			

			TurnCamera(90.f, -40.f);
			SpawnSmashers(8, 2.f);

			UHazeAkComponent::HazePostEventFireForget(PendulumFallInnerEvent, GetActorTransform());
			//PrintScaled("DestroyInner", 2.f, FLinearColor::Black, 2.f);
		}
		else
		{
			SetPendulumTimerEnabled(true);
			PendulumSwingTimer = 0.f;
			System::SetTimer(this, n"PlaySwingCamShake", 1.5f, false);

			UHazeAkComponent::HazePostEventFireForget(PendulumSwingEvent, GetActorTransform());
			//PrintScaled("Pendulum", 2.f, FLinearColor::Black, 2.f);

			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for(AHazePlayerCharacter Player : Players)
				Player.PlayForceFeedback(PendulumFeedback, false, false, n"PendulumSwing");	
			
			for (int i = 0; i < PendulumArray.Num(); i++)
			{
				if (Swing.PendulumNumbers.Contains(PendulumArray[i].PendulumIndex))
				{
					PendulumArray[i].SwingPendulum();
					PendulumArray[i].SetPendulumToVoTrigger();
				}
				else
					PendulumArray[i].SetPendulumSwingRotation();	
			}

			bArePendulumsReversed = !bArePendulumsReversed;
		}
	}

	UFUNCTION()
	void PlayOuterRingVO()
	{
		PlayFoghornVOBankEvent(VoBank, n"FoghornDBClockworkUpperTowerClockBossPendulumHalfway");	
	}

	UFUNCTION()
	void PlaySwingCamShake()
	{
		Game::GetCody().PlayCameraShake(PendulumSwingShake);
	}

	UFUNCTION()
	void PendulumLeftPlatform()
	{
		// Turn the camera as soon as the pendulums are done swinging,
		// but only if we aren't going into a special phase next.
		if (PendulumSequenceIndex < Sequence.Sequence.Num())
		{
			const FClockworkPendulumSwing& Swing = Sequence.Sequence[PendulumSequenceIndex];
			if (Swing.Phase == EClockworkPendulumPhase::None)
			{
				if (bFacingReversePendulums && !bArePendulumsReversed)
				{
					TurnCamera(-180.f, -25.f);		
					bFacingReversePendulums = false;
				}
				else if (!bFacingReversePendulums && bArePendulumsReversed)
				{
					TurnCamera(180.f, -25.f);		
					bFacingReversePendulums = true;
				}
			}
		}
	}

	UFUNCTION()
	void StartSwingingPendulumEvent()
	{
		//Super::StartEvent();

		StartedEvent.Broadcast(EventNumber);

		bEventIsActive = true;

		for (auto Player : Game::Players)
			RespawnCheckpoint.EnableForPlayer(Player);
	}

	UFUNCTION()
	void SetPendulumTimerEnabled(bool bEnabled)
	{
		PendulumSwingTimer = 0.f;
		bShouldTickPendulumTimer = bEnabled;
	}

	UFUNCTION()
	void AngerClockFace()
	{
		ClockFace.TurnClockFaceRed(true, 2.f, true, true);
	}

	UFUNCTION()
	void SwingRandomPendulums(int AmountToSwing)
	{
	}

	UFUNCTION()
	void SetCamera(AClockworkLastBossSwingingPendulumEventCamera CameraToSet)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.f;
		Game::GetCody().ActivateCamera(CameraToSet.Camera, Blend, this);
	}

	UFUNCTION()
	void TurnCameraTimelineUpdate(float CurrentValue)
	{
		float Alpha = FMath::SinusoidalInOut(0.f, 1.f, CurrentValue);
		EventCamera01.SetActorRotation(FMath::LerpShortestPath(CamStartRot, CamTargetRot, Alpha));
	}

	UFUNCTION()
	void TurnCamera(float NewCamTargetRotYaw, float NewCamTargetRotPitch)
	{
		CamStartRot = EventCamera01.GetActorRotation();
		CamTargetRot = CamStartRot + FRotator(0.f, NewCamTargetRotYaw, 0.f);
		CamTargetRot.Pitch = NewCamTargetRotPitch;
		bCameraHasBeenTurned = false;
		TurnCameraTimeline.PlayFromStart();
	}

	UFUNCTION()
	void PendulumCamShakeTimelineUpdate(float CurrentValue)
	{
		Game::GetCody().PlayCameraShake(PendulumSwingShake, CurrentValue * 10.f);
		PrintToScreen("Value: " + CurrentValue);
	}

	void SpawnSmashers(int Amount, float SpawnDelay)
	{
		if (!bSmasherReadyToSpawn)
		{
			SmashAmount = Amount;
			SmasherDelay = SpawnDelay;
			SmashTimer = SpawnDelay;
			bSmashTimerActive = true;
			return;
		}
		else 
		{
			for (int i = 0; i < SmashAmount; i++)
			{
				float SmashTimerDelay = i / 6.f;
				SmasherArray[i].StartSmashFromTimer(SmashTimerDelay);
			}

			for (int i = 0; i < SmashAmount; i++)
			{
					SmasherArray.RemoveAt(0);
			}

			bSmasherReadyToSpawn = false;

			if (SmasherArray.Num() != 0)
				System::SetTimer(this, n"ReActivatePendulum", 5.f, false);
			else
				System::SetTimer(this, n"CompleteEvent", 5.f, false);
		}
	}

	UFUNCTION()
	void ReActivatePendulum()
	{
		TurnCamera(90.f, -25.f);
		bFacingReversePendulums = bArePendulumsReversed;

		ProgressPendulumSequence();
	}

	UFUNCTION()
	void CompleteEvent()
	{
		FinishedEvent.Broadcast(EventNumber);
		Game::GetCody().DeactivateCameraByInstigator(this);
		Game::GetCody().StopAllCameraShakes(true);

		for (auto Player : Game::Players)
			RespawnCheckpoint.DisableForPlayer(Player);
	}

	TArray<AClockworkLastBossSmasher> SortSmasherArray(TArray<AClockworkLastBossSmasher> NewOldArray)
	{
		TArray<AClockworkLastBossSmasher> OldArray = NewOldArray;
		TArray<AClockworkLastBossSmasher> SortedArray;

		int LowestStartNumber = 99;
		int LowestStartNumberIndex = 99;

		while(OldArray.Num() > 0)
		{
			for (int i = 0; i < OldArray.Num(); i++)
			{
				if (OldArray[i].SmashOrder < LowestStartNumber)
				{
					LowestStartNumber = OldArray[i].SmashOrder;
					LowestStartNumberIndex = i;
				}
			}

			SortedArray.Add(OldArray[LowestStartNumberIndex]);
			OldArray.RemoveAt(LowestStartNumberIndex);
			LowestStartNumber = 99;
			LowestStartNumberIndex = 99;
		}

		return SortedArray;
	}
}

struct FClockworkPendulumSwing
{
	EClockworkPendulumPhase Phase = EClockworkPendulumPhase::None;
	TArray<int> PendulumNumbers;

	FClockworkPendulumSwing(EClockworkPendulumPhase TriggerPhase)
	{
		Phase = TriggerPhase;
	}

	FClockworkPendulumSwing(int Number1)
	{
		PendulumNumbers.Add(Number1);
	}

	FClockworkPendulumSwing(int Number1, int Number2)
	{
		PendulumNumbers.Add(Number1);
		PendulumNumbers.Add(Number2);
	}

	FClockworkPendulumSwing(int Number1, int Number2, int Number3)
	{
		PendulumNumbers.Add(Number1);
		PendulumNumbers.Add(Number2);
		PendulumNumbers.Add(Number3);
	}

	FClockworkPendulumSwing(int Number1, int Number2, int Number3, int Number4)
	{
		PendulumNumbers.Add(Number1);
		PendulumNumbers.Add(Number2);
		PendulumNumbers.Add(Number3);
		PendulumNumbers.Add(Number4);
	}
};
