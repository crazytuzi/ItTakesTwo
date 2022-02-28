import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingStartInteraction;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingTargetManager;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingDoublePoints;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingDoors;
import Vino.Interactions.DoubleInteractionActor;

AAxeThrowingGameManager GetAxeThrowingGameManager()
{
	TArray<AAxeThrowingGameManager> AxeThrowingGameManagerArray; 
	AAxeThrowingGameManager AxeThrowingGameManager;

	GetAllActorsOfClass(AxeThrowingGameManagerArray);
	AxeThrowingGameManager = AxeThrowingGameManagerArray[0];

	return AxeThrowingGameManager;
}

class AAxeThrowingGameManager : ADoubleInteractionActor
{
	default LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May);
	default RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
	default bPreventInteractionFromCompleting = true;
	default bPlayExitAnimationOnCompleted = true;
	default bTurnOffTickWhenNotWaiting = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::IcicleThrowing;

	UPROPERTY(DefaultComponent, Attach = LeftInteraction)
	UBillboardComponent LeftIcicleLocation;

	UPROPERTY(DefaultComponent, Attach = RightInteraction)
	UBillboardComponent RightIcicleLocation;

	UPROPERTY(Category = "Setup")
	TPerPlayer<AAxeThrowingStartInteraction> AxeThrowingStartInteraction;

	UPROPERTY(Category = "Setup")
	AAxeThrowingTargetManager TargetManager;

	UPROPERTY(Category = "Setup")
	AAxeThrowingAxeManager AxeManager;

	UPROPERTY(Category = "Setup")
	TPerPlayer<AAxeThrowingDoors> FenceOpenings;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY(Category = "Setup")
	TArray<AAxeThrowingDoublePoints> DoublePointsMay;
	
	UPROPERTY(Category = "Setup")
	TArray<AAxeThrowingDoublePoints> DoublePointsCody;

	UPROPERTY(Category = "Setup")
	TPerPlayer<AHazeActor> IcicleProp;

	UPROPERTY(Category = "HoopSequences")
	TArray<int> Sequences1;
	
	UPROPERTY(Category = "HoopSequences")
	TArray<int> Sequences2;
	
	UPROPERTY(Category = "HoopSequences")
	TArray<int> Sequences3;

	UPROPERTY(Category = "Player Feedback")
	TSubclassOf<UCameraShakeBase> DoublePointShake;

	UPROPERTY(Category = "Animations")
	TPerPlayer<UAnimSequence> LeaveAnimations;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartMachinary;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EndMachinary;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TargetsSpeedUp;

	FHazeAcceleratedFloat AudioAccelValue;

	bool bAudioMachineSpedUp;

	TArray<int> ChosenSequence;

	TPerPlayer<UAxeThrowingPlayerComp> PlayerComps;

	bool bHaveCompletedTutorial;

	float TimePercentage;
	float MaxTimer;

	int PlayersActive;

	float TimeToEnableMay;
	float TimeToEnableCody;
	float DefaultTimeToEnable = 0.7f;

	bool bMayIn;
	bool bCodyIn;

	int PlayRate;
	int MinPlay = 1;
	int MaxPlay = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		LeftInteraction.OnActivated.AddUFunction(this, n"OnPlayerInteracted");
		RightInteraction.OnActivated.AddUFunction(this, n"OnPlayerInteracted");

		OnBothPlayersLockedIntoInteraction.AddUFunction(this, n"PlayersLockedIn");
		
		OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnPlayerCancelled");

		TargetManager.OnTargetHitScore.AddUFunction(this, n"TargetHitScore");
		TargetManager.OnSpeedUpActivated.AddUFunction(this, n"SpeedUpActive");

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"InitiateGame");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"GameCancelled");

		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"StartGame");
		MinigameComp.OnTimerCompletedEvent.AddUFunction(this, n"HandleTimerCompleted");
		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"EndGame");
		
		MaxTimer = MinigameComp.ScoreData.Timer;

		AudioResetMachinaryRTCP();

		DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (MinigameComp.bCanTimer)
		{
			TimePercentage = MinigameComp.GetTimerValue() / MaxTimer;

			if (!bAudioMachineSpedUp)
				AudioSetMachinaryRTCP(1.f, DeltaTime);
			else
				AudioSetMachinaryRTCP(1.5f, DeltaTime);

			if (TimePercentage <= 0.85f && TimePercentage >= 0.6f)
				SetHoopSequence(ChosenSequence[0]);
			else if (TimePercentage <= 0.6f && TimePercentage >= 0.4f)
				SetHoopSequence(ChosenSequence[1]);
			else if (TimePercentage <= 0.4f && TimePercentage >= 0.2f)
				SetHoopSequenceDouble(ChosenSequence[2], ChosenSequence[3]);
			else if (TimePercentage <= 0.2f && TimePercentage >= 0.f)
				SetHoopSequenceDouble(ChosenSequence[3], ChosenSequence[1]);
		}
		else
		{
			AudioSetMachinaryRTCP(0.f, DeltaTime);
		}
	}

	UFUNCTION()
	void EnableGameManager()
	{
		if (IsActorDisabled())
			EnableActor(this);
	}
	
	UFUNCTION()
	void PlayCameraShake(AHazePlayerCharacter Player)
	{
		Player.PlayCameraShake(DoublePointShake);
	}

	UFUNCTION()
	void OnPlayerInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{		
		Player.BlockCapabilities(n"SnowballFight", this);
		Player.AddCapabilitySheet(CapabilitySheet, EHazeCapabilitySheetPriority::High);

		if (Player.IsMay())
			PlayerComps[0] = UAxeThrowingPlayerComp::Get(Game::May);
		else
			PlayerComps[1] = UAxeThrowingPlayerComp::Get(Game::Cody);

		UAxeThrowingPlayerComp PlayerComp = UAxeThrowingPlayerComp::Get(Player);

		if (PlayerComp != nullptr)
		{
			PlayerComp.OurInteractionComp = InteractComp;
			PlayerComp.PlayerAxeState = EPlayerAxeState::PickingUpAxe;
			PlayerComp.AxePlayerGameState = EAxePlayerGameState::BeforePlay;
			PlayerComp.IcicleProp = IcicleProp[Player];

			if (Player == Game::May)
			{
				PlayerComp.StartInteraction = AxeThrowingStartInteraction[0];
				bMayIn = true;
			}
			else
			{
				PlayerComp.StartInteraction = AxeThrowingStartInteraction[1];
				bCodyIn = true;
			}
		}

		if (bMayIn && bCodyIn)
		{
			PlayerComps[0] = UAxeThrowingPlayerComp::Get(Game::May);
			PlayerComps[1] = UAxeThrowingPlayerComp::Get(Game::Cody);
			
			PlayerComps[0].AxePlayerGameState = EAxePlayerGameState::BeforePlay;
			PlayerComps[1].AxePlayerGameState = EAxePlayerGameState::BeforePlay;

			PlayerComps[0].bCanCancel = false;
			PlayerComps[1].bCanCancel = false;

			PlayerComps[0].RemoveCancelPrompt(Game::May);
			PlayerComps[1].RemoveCancelPrompt(Game::Cody);

			PlayerComps[0].SetGameFinished(false);
			PlayerComps[1].SetGameFinished(false);

			PlayerComps[0].SetCanShoot(false);
			PlayerComps[1].SetCanShoot(false);

			FenceOpenings[0].SetDoorOpen();
			FenceOpenings[1].SetDoorOpen();

			bPreventInteractionFromCompleting = true;
		}
	}

	UFUNCTION()
	void PlayersLockedIn()
	{
		MinigameComp.ActivateTutorial();
	}

	UFUNCTION()
	void GameCancelled()
	{
		if (HasControl())
			NetGameCancelled();	
	}

	UFUNCTION(NetFunction)
	void NetGameCancelled()
	{
		UAxeThrowingPlayerComp PlayerCompMay = UAxeThrowingPlayerComp::Get(Game::May);
		UAxeThrowingPlayerComp PlayerCompCody = UAxeThrowingPlayerComp::Get(Game::Cody);

		PlayerCompMay.SetCanShoot(true);
		PlayerCompCody.SetCanShoot(true);

		PlayerCompMay.bCanCancel = true;
		PlayerCompCody.bCanCancel = true;

		Game::May.RemoveCapabilitySheet(CapabilitySheet);
		Game::Cody.RemoveCapabilitySheet(CapabilitySheet);

		PlayLeaveAnimation(Game::May);
		PlayLeaveAnimation(Game::Cody);

		FenceOpenings[0].SetDoorClosed();
		FenceOpenings[1].SetDoorClosed();
		
		System::SetTimer(this, n"DelayedReturnAxeToOrigin", 0.3f, false);

		PlayersActive = 0;

		bMayIn = false;
		bCodyIn = false;
	}

	UFUNCTION()
	void InitiateGame()
	{
		MinigameComp.StartCountDown();
		
		PlayerComps[0].AxePlayerGameState = EAxePlayerGameState::InPlay;
		PlayerComps[1].AxePlayerGameState = EAxePlayerGameState::InPlay;
	}

	UFUNCTION()
	void OnPlayerCancelled(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{		
		if (Player == Game::May)
		{
			UAxeThrowingPlayerComp PlayerCompMay = UAxeThrowingPlayerComp::Get(Game::May);
			PlayerCompMay.SetCanShoot(true);
			TimeToEnableMay = DefaultTimeToEnable;
			
			bMayIn = false;

			System::SetTimer(this, n"DelayedReturnAxeToOriginMay", 0.3f, false);
		}
		else
		{
			UAxeThrowingPlayerComp PlayerCompCody = UAxeThrowingPlayerComp::Get(Game::Cody);
			PlayerCompCody.SetCanShoot(true);	
			TimeToEnableCody = DefaultTimeToEnable;

			bCodyIn = false;

			System::SetTimer(this, n"DelayedReturnAxeToOriginCody", 0.3f, false);
		}

		Player.RemoveCapabilitySheet(CapabilitySheet);

		if (Player.IsMay())
			PlayLeaveAnimation(Game::May);
		else
			PlayLeaveAnimation(Game::Cody);

		bPreventInteractionFromCompleting = false;

		PlayersActive--;
	} 

	UFUNCTION()
	void PlayLeaveAnimation(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.TriggerMovementTransition(this);

		FHazeAnimationDelegate BlendOut;

		if (Player.IsMay())
		{
			BlendOut.BindUFunction(this, n"ExitLeaveAnimationMay");
			Player.PlaySlotAnimation(Animation = LeaveAnimations[0], BlendTime = 0.3f, OnBlendingOut = BlendOut);
		}
		else
		{
			BlendOut.BindUFunction(this, n"ExitLeaveAnimationCody");
			Player.PlaySlotAnimation(Animation = LeaveAnimations[1], BlendTime = 0.3f, OnBlendingOut = BlendOut);
		}
	}

	UFUNCTION()
	void ExitLeaveAnimationMay()
	{
		Game::May.UnblockCapabilities(n"SnowballFight", this);
		Game::May.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::May.UnblockCapabilities(CapabilityTags::Interaction, this);
		bPreventInteractionFromCompleting = false;
	}

	UFUNCTION()
	void ExitLeaveAnimationCody()
	{
		Game::Cody.UnblockCapabilities(n"SnowballFight", this);
		Game::Cody.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::Cody.UnblockCapabilities(CapabilityTags::Interaction, this);
		bPreventInteractionFromCompleting = false;
	}

	UFUNCTION()
	void StartGame()
	{
		TargetManager.BeginSpawn();

		AudioStartMachinaryEvent();

		bPreventInteractionFromCompleting = false;

		if (!bHaveCompletedTutorial)
		{
			PlayerComps[0].ShowRightTrigger(Game::May);
			PlayerComps[1].ShowRightTrigger(Game::Cody);
			PlayerComps[0].bShowingTutorial = true;
			PlayerComps[1].bShowingTutorial = true;
			bHaveCompletedTutorial = true;
		}

		PlayerComps[0].SetCanShoot(true);
		PlayerComps[1].SetCanShoot(true);	

		Game::Cody.BlockCapabilities(CapabilityTags::Interaction, this);
		Game::May.BlockCapabilities(CapabilityTags::Interaction, this);

		ChooseHoopSequence();
	}

	void ChooseHoopSequence()
	{
		int R = FMath::RandRange(0, 2);

		switch(R)
		{
			case 0: ChosenSequence = Sequences1; break;
			case 1: ChosenSequence = Sequences2; break;
			case 2: ChosenSequence = Sequences3; break;
		}
	}

	UFUNCTION()
	void SetHoopSequence(int Index)
	{
		for (int i = 0; i < DoublePointsMay.Num(); i++)
		{
			if (i == Index)
			{		
				DoublePointsMay[i].ActivateHoop();
				DoublePointsCody[i].ActivateHoop();
			}
			else
			{
				DoublePointsMay[i].DeactivateHoop();
				DoublePointsCody[i].DeactivateHoop();			
			}
		}	
	}
	
	UFUNCTION()
	void SetHoopSequenceDouble(int Index1, int Index2)
	{
		for (int i = 0; i < DoublePointsMay.Num(); i++)
		{
			if (i == Index1 || i == Index2)
			{		
				DoublePointsMay[i].ActivateHoop();
				DoublePointsCody[i].ActivateHoop();
			}
			else
			{
				DoublePointsMay[i].DeactivateHoop();
				DoublePointsCody[i].DeactivateHoop();			
			}
		}
	}

	void ResetHoopSequence()
	{
		for (AAxeThrowingDoublePoints DB : DoublePointsMay)
			DB.DeactivateHoop();
		
		for (AAxeThrowingDoublePoints DB : DoublePointsCody)
			DB.DeactivateHoop();
	}

	UFUNCTION()
	void TargetHitScore(AHazePlayerCharacter Player, float Score, FVector HitLocation, bool bIsDoublePoints)
	{
		MinigameComp.AdjustScore(Player, Score);
		FVector NewHitLoc = HitLocation + FVector(0.f, 0.f, 250.f);
		
		FMinigameWorldWidgetSettings MinigameWorldSettings;
		
		MinigameWorldSettings.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
		MinigameWorldSettings.MoveSpeed = 30.f;
		MinigameWorldSettings.TimeDuration = 0.5f;
		MinigameWorldSettings.FadeDuration = 0.6f;
		MinigameWorldSettings.TargetHeight = 140.f;

		if (Player == Game::May)
			MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::May;
		else
			MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::Cody;

		if (bIsDoublePoints)
		{
			PlayCameraShake(Player);
			MinigameComp.PlayTauntAllVOBark(Player);
		}

		if (Player == Game::May)
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::May, "+ " + String::Conv_IntToString(Score), NewHitLoc, MinigameWorldSettings);
		else
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Cody, "+ " + String::Conv_IntToString(Score), NewHitLoc, MinigameWorldSettings);
	}

	UFUNCTION()
	void SpeedUpActive()
	{
		MinigameComp.PlayMessageAnimation(NSLOCTEXT("Minigames", "SpeedItUp", "Speed It Up"));
		AkComp.HazePostEvent(TargetsSpeedUp);
		bAudioMachineSpedUp = true;
	}

	UFUNCTION()
	void HandleTimerCompleted()
	{
		if (HasControl())
			NetAnnounceWinner(MinigameComp.ScoreData.MayScore, MinigameComp.ScoreData.CodyScore);
	}

	UFUNCTION(NetFunction)
	void NetAnnounceWinner(int MayScore, int CodyScore)
	{
		Game::May.SetAnimBoolParam(n"bExitingIcicleGame", true);
		Game::Cody.SetAnimBoolParam(n"bExitingIcicleGame", true);

		Game::May.SetAnimBoolParam(n"bExitingIcicleGame", true);
		Game::Cody.SetAnimBoolParam(n"bExitingIcicleGame", true);

		MinigameComp.SetScore(Game::May, MayScore);
		MinigameComp.SetScore(Game::Cody, CodyScore);
		
		System::SetTimer(this, n"TimedAnnounceWinner", 1.5f, false);

		FenceOpenings[0].SetDoorClosed();
		FenceOpenings[1].SetDoorClosed();
			
		PlayerComps[0].PlayerAxeState = EPlayerAxeState::Default;
		PlayerComps[1].PlayerAxeState = EPlayerAxeState::Default;

		if (PlayerComps[0].bShowingTutorial)
			PlayerComps[0].RemoveRightTrigger(Game::May);

		if (PlayerComps[1].bShowingTutorial)
			PlayerComps[1].RemoveRightTrigger(Game::Cody);

		System::SetTimer(this, n"DelayedReturnAxeToOrigin", 0.3f, false);
	}

	UFUNCTION()
	void DelayedReturnAxeToOrigin()
	{
		PlayerComps[0].ReturnAxeToOrigin();
		PlayerComps[1].ReturnAxeToOrigin();
	}

	UFUNCTION()
	void DelayedReturnAxeToOriginMay()
	{
		PlayerComps[0].ReturnAxeToOrigin();
	}

	UFUNCTION()
	void DelayedReturnAxeToOriginCody()
	{
		PlayerComps[1].ReturnAxeToOrigin();
	}

	UFUNCTION()
	void TimedAnnounceWinner()
	{
		MinigameComp.AnnounceWinner();

		bAudioMachineSpedUp = false;
		
		PlayerComps[0].SetGameFinished(true);
		PlayerComps[1].SetGameFinished(true);

		TargetManager.TargetsEndGame();

		UAxeThrowingPlayerComp PlayerCompMay = UAxeThrowingPlayerComp::Get(Game::May);
		UAxeThrowingPlayerComp PlayerCompCody = UAxeThrowingPlayerComp::Get(Game::Cody);

		PlayerComps[0].AxePlayerGameState = EAxePlayerGameState::WinnerAnnouncement;
		PlayerComps[1].AxePlayerGameState = EAxePlayerGameState::WinnerAnnouncement;
	}

	UFUNCTION()
	void EndGame()
	{
		PlayerComps[0].bCanCancel = true;
		PlayerComps[1].bCanCancel = true;

		MinigameComp.ResetScoreBoth();
		MinigameComp.EndGameHud();

		PlayerComps[0].AxePlayerGameState = EAxePlayerGameState::Inactive;
		PlayerComps[1].AxePlayerGameState = EAxePlayerGameState::Inactive;

		PlayerComps[0].SetGameFinished(false);
		PlayerComps[1].SetGameFinished(false);	

		PlayerComps[0].ReturnAxeToOrigin();
		PlayerComps[1].ReturnAxeToOrigin();

		Game::May.RemoveCapabilitySheet(CapabilitySheet);
		Game::Cody.RemoveCapabilitySheet(CapabilitySheet);

		Game::May.UnblockCapabilities(n"SnowballFight", this);
		Game::Cody.UnblockCapabilities(n"SnowballFight", this);

		Game::May.UnblockCapabilities(CapabilityTags::Interaction, this);
		Game::Cody.UnblockCapabilities(CapabilityTags::Interaction, this);

		ResetHoopSequence();

		bMayIn = false;
		bCodyIn = false;

		AudioEndMachinaryEvent();
	}

	void AudioResetMachinaryRTCP()
	{
		AudioAccelValue.SnapTo(0.f);
	}

	void AudioSetMachinaryRTCP(float Value, float DeltaTime)
	{
		AudioAccelValue.AccelerateTo(Value, 1.f, DeltaTime);
		AkComp.SetRTPCValue("Rtpc_SideContent_Snowglobe_Minigame_IcicleThrowing_MachineryLoop_Speed", AudioAccelValue.Value);
	}

	void AudioStartMachinaryEvent()
	{
		AkComp.HazePostEvent(StartMachinary);
	}

	void AudioEndMachinaryEvent()
	{
		AkComp.HazePostEvent(EndMachinary);
	}
}