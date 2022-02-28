import void InitMusicalChairsComp(AHazePlayerCharacter Player, AMusicalChairsActor MusicalChairsActor) from "Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent";
import Vino.Tutorial.TutorialStatics;
import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.MinigameScore.MinigameComp;
import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractionActor;
import Peanuts.Animation.Features.Music.LocomotionFeatureMusicalChairs;

event void FOnMusicalChairsMusicStarted();
event void FOnMusicalChairsMusicStopped();
event void FOnMusicalChairsGameOver();

UCLASS(Abstract)
class AMusicalChairsActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpeakerRoot;

	UPROPERTY(DefaultComponent, Attach = SpeakerRoot)
	UNiagaraComponent NotesFX;

	UPROPERTY(DefaultComponent, Attach = SpeakerRoot)
	UNiagaraComponent FailEffect;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ChairRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonPromptRoot;

	UPROPERTY(DefaultComponent, Attach = ChairRoot)
	USceneComponent SitLocation;

	UPROPERTY(DefaultComponent, Attach = ChairRoot)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent MayAttachComp;

	UPROPERTY(DefaultComponent, Attach = MayAttachComp)
	USceneComponent MaySpecificButtonPromptRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent CodyAttachComp;

	UPROPERTY(DefaultComponent, Attach = CodyAttachComp)
	USceneComponent CodySpecificButtonPromptRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponentBase FollowSpline;

	UPROPERTY(DefaultComponent)
	UInteractionComponent MinigameCodySideInteraction;
 	default MinigameCodySideInteraction.ActivationSettings.ActivationType = EHazeActivationType::Invalid;
    default MinigameCodySideInteraction.ActionShape.Type = EHazeShapeType::None;
    default MinigameCodySideInteraction.FocusShape.Type = EHazeShapeType::None;
    default MinigameCodySideInteraction.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysCody;

	UPROPERTY(DefaultComponent)
	UInteractionComponent MinigameMaySideInteraction;
	default MinigameMaySideInteraction.ActivationSettings.ActivationType = EHazeActivationType::Invalid;
    default MinigameMaySideInteraction.ActionShape.Type = EHazeShapeType::None;
    default MinigameMaySideInteraction.FocusShape.Type = EHazeShapeType::None;
    default MinigameMaySideInteraction.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysMay;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent AkComponent;

	// UPROPERTY(DefaultComponent)
	// UHazeSmoothSyncRotationComponent SyncedRotationComp;
	// default SyncedRotationComp.NumberOfSyncsPerSecond = 10;

	// UPROPERTY(DefaultComponent)
	// UDoubleInteractComponent DoubleInteract;

	// UPROPERTY(DefaultComponent, Attach = ChairRoot)
	// UInteractionComponent MayInteraction;

	// UPROPERTY(DefaultComponent, Attach = ChairRoot)
	// UInteractionComponent CodyInteraction;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent MinigameCamera;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent WinningCamera;

	UPROPERTY(DefaultComponent)
	USceneComponent LosingCameraRoot;

	UPROPERTY(DefaultComponent, Attach = LosingCameraRoot)
	UHazeCameraComponent LosingCamera;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::MusicalChairs;

	// UPROPERTY(NotEditable)
	// UScoreHud ScoreHud;

	// UPROPERTY(Category = "Setup")
	// TSubclassOf<UScoreHud> ScoreHudClass;

	UPROPERTY(BlueprintReadOnly)
	TSubclassOf<UHazeInputButton> InputButtonClass;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	ULocomotionFeatureMusicalChairs CodyAnimFeature;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	ULocomotionFeatureMusicalChairs MayAnimFeature;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayGetReady;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyGetReady;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayReadyMH;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyReadyMH;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayWinLanding;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyWinLanding;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayResetLanding;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyResetLanding;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem LoserEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem MayRespawnEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem CodyRespawnEffect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LoserRumble;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LandOnChairRumble;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MusicalChairsSeatHitFloor;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayRespawnEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyRespawnEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayDeathEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyDeathEvent;

	UPROPERTY()
	FOnMusicalChairsMusicStarted OnMusicalChairsMusicStarted;
	UPROPERTY()
	FOnMusicalChairsMusicStopped OnMusicalChairsMusicStopped;
	UPROPERTY()
	FOnMusicalChairsGameOver OnMusicalChairsGameOver;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	bool bMayIsReady = false;
	bool bCodyIsReady = false;

	bool bMayCapabilitiesAdded = false;
	bool bCodyCapabilitiesAdded = false;

	bool bMiniGameIsOn = false;
	bool bCountDownFinished = false;

	bool bShowButtonPrompt = false;

	float MinPlayingDuration = 6.0f;
	float MaxPlayingDuration = 15.0f;
	float CurrentPlayingDuration = 0.0f;

	UPROPERTY()
	bool bSongIsStopped = true;

	bool bGameOver = false;

	//int AmountOfRounds = 3;
	int RoundNumber = 0;

	bool bMayFinishedAnimations = false;
	bool bCodyFinishedAnimations = false;

	UPROPERTY(Category = "Setup")
	FScoreHudData GameScoreData;
	default GameScoreData.ScoreLimit = 3.f;
	default GameScoreData.ScoreMode = EScoreMode::FirstTo;

	bool bRoundOver = false;
	bool bRoundEnded = false;

	EMusicalChairsRoundWinState WinState;

	EMusicalChairsButtonType RoundButtonType;

	EMusicalChairsButtonType LastRoundButtonType;

	AHazePlayerCharacter FullscreenedPlayer;

	// UPROPERTY(Category = "Setup")
	// FText RoundOneText;
	// UPROPERTY(Category = "Setup")
	// FText RoundTwoText;
	// UPROPERTY(Category = "Setup")
	// FText RoundThreeText;

	bool bTutorialWasCancelled = false;
	bool bFinishedTutorial= false;

	bool bMayCancelledInteraction = false;
	bool bCodyCancelledInteraction = false;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteractActor;

	bool bWinnerReachedSeat = false;

	int ScoreLimit = 3;
	int MinimumWinningScore = 2;

	AHazePlayerCharacter PlayerOnChair = nullptr;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ResetTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FlyUpTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DanceTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DanceSmallVibesTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GameScoreData.MayScore = 0;
		GameScoreData.CodyScore = 0;

		AddCapability(n"MusicalChairsPlayingRoundCapability");
		AddCapability(n"MusicalChairsEndOfRoundCapability");
		AddCapability(n"MusicalChairsGameOverCapability");
		AddCapability(n"MusicalChairsRadioDancingCapability");
		AddCapability(n"MusicalChairsPromptCapability");

		NotesFX.Deactivate();
		FailEffect.Deactivate();

		DoubleInteractActor.OnLeftInteractionReady.AddUFunction(this, n"OnLeftInteracted");
		DoubleInteractActor.OnRightInteractionReady.AddUFunction(this, n"OnRightInteracted");
		DoubleInteractActor.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnInteractionCancelled");
		DoubleInteractActor.OnDoubleInteractionCompleted.AddUFunction(this, n"DoubleInteractFinished");
		
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"TutorialWasCancelled");
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"TutorialCompleted");


		MinigameMaySideInteraction.OnActivated.AddUFunction(this, n"MinigameOnInteracted");
		MinigameCodySideInteraction.OnActivated.AddUFunction(this, n"MinigameOnInteracted");

	}
	
	UFUNCTION()
	void MinigameOnInteracted(UInteractionComponent Component, AHazePlayerCharacter Player)
	{	
		if(HasControl())
		{
			if(Player.IsMay())
				WinState = EMusicalChairsRoundWinState::MayWon;
			else
				WinState = EMusicalChairsRoundWinState::CodyWon;
				
			NetDecideRoundWinner(WinState);	
		}
	}

	UFUNCTION()
	EMusicalChairsRoundWinState CheckWinState(EMusicalChairsButtonType PressedButton, AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
		{
			if(PressedButton == RoundButtonType)
			{
				return EMusicalChairsRoundWinState::MayWon;
			}
			else
			{
				return EMusicalChairsRoundWinState::MayLost;
			}
		}
		else
		{
			if(PressedButton == RoundButtonType)
			{
				return EMusicalChairsRoundWinState::CodyWon;
			}
			else
			{
				return EMusicalChairsRoundWinState::CodyLost;
			}
		}
	}

	
	UFUNCTION()
	bool DidPlayerWin(EMusicalChairsButtonType PressedButton, AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
		{
			if(PressedButton == RoundButtonType)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			if(PressedButton == RoundButtonType)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
	}


	UFUNCTION()
	void DoubleInteractFinished()
	{ 
		DoubleInteractActor.DisableActor(this);
		StartTutorial();
	}

	UFUNCTION()
	void OnInteractionCancelled(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		if(Player.IsMay())
		{
			bMayCancelledInteraction = true;
		}
		else
		{
			bCodyCancelledInteraction = true;
		}

 		//Player.RemoveCancelPromptByInstigator(this);
		
		CancelPlayer(Player);
	}

	UFUNCTION()
	void CancelPlayer(AHazePlayerCharacter Player)
	{
		if(Player.IsMay() && bMayIsReady)
		{
			bMayIsReady = false;
		}
		else if(Player.IsCody() && bCodyIsReady)
		{
			bCodyIsReady = false;
		}

		Player.DeactivateCamera(MinigameCamera);

		Player.SetCapabilityActionState(n"ReadyForMusicalChairs", EHazeActionState::Inactive);
		Player.SetCapabilityActionState(n"StartMusicalChairs", EHazeActionState::Inactive);
	}

	UFUNCTION()
	void OnLeftInteracted(AHazePlayerCharacter Player)
	{
		AddPlayerToMusicalChairs(Player);	

		bMayIsReady = true;

		//Player.ShowCancelPrompt(this);

		FHazeCameraBlendSettings BlendSettings;
		Player.ActivateCamera(MinigameCamera, BlendSettings, this, EHazeCameraPriority::Script);
		FullscreenedPlayer = Player;
	}
	
	UFUNCTION()
	void OnRightInteracted(AHazePlayerCharacter Player)
	{
		AddPlayerToMusicalChairs(Player);	

		bCodyIsReady = true;

		//Player.ShowCancelPrompt(this);

		FHazeCameraBlendSettings BlendSettings;
		Player.ActivateCamera(MinigameCamera, BlendSettings, this, EHazeCameraPriority::Script);
		FullscreenedPlayer = Player;
	}	

	void PlayReadyAnimation(AHazePlayerCharacter Player)
	{
		UAnimSequence GetReady = Player.IsMay() ? MayGetReady : CodyGetReady;

		FName FunctionName = Player.IsMay() ? n"OnMayGetReadyFinished" : n"OnCodyGetReadyFinished";

		FHazeAnimationDelegate BlendingOut;
		BlendingOut.BindUFunction(this, FunctionName);
	
		Player.PlaySlotAnimation(Animation = GetReady, bLoop = false, OnBlendingOut = BlendingOut);
	}

	UFUNCTION()
	void OnMayGetReadyFinished()
	{
		PlayReadyMH(Game::GetMay());
	}

	UFUNCTION()
	void OnCodyGetReadyFinished()
	{
		PlayReadyMH(Game::GetCody());
	}

	void PlayReadyMH(AHazePlayerCharacter Player)
	{
		UAnimSequence ReadyMH = Player.IsMay() ? MayReadyMH : CodyReadyMH;

		Player.PlaySlotAnimation(Animation = ReadyMH, bLoop = true);
	}
	
	UFUNCTION()
	void TutorialWasCancelled()
	{
		bTutorialWasCancelled = true;
		ResetMusicalChairs();
	}

	UFUNCTION()
	void TutorialCompleted()
	{
		bFinishedTutorial = true;
	}

	UFUNCTION()
	void StartTutorial()
	{
		PlayReadyAnimation(Game::GetMay());
		PlayReadyAnimation(Game::GetCody());
		
		MinigameComp.ActivateTutorial();
	}

	UFUNCTION(NetFunction)
	void NetDecideButtonType(EMusicalChairsButtonType ButtonType)
	{
		RoundButtonType = ButtonType;
	}

	UFUNCTION(NetFunction)
	void NetDecidePlayingDuration(float PlayingDuration)
	{
		CurrentPlayingDuration = PlayingDuration;
	}

	UFUNCTION()
	void StartMusicalChairs()
	{
		Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);

		Game::GetMay().DisableOutlineByInstigator(this);
		Game::GetCody().DisableOutlineByInstigator(this);

		bMiniGameIsOn = true;

		if(HasControl())
		{
			CurrentPlayingDuration = FMath::RandRange(MinPlayingDuration, MaxPlayingDuration);
			LastRoundButtonType = RoundButtonType;
			RoundButtonType = EMusicalChairsButtonType(FMath::RandRange(0, 3));

			if(RoundButtonType == LastRoundButtonType)
				RoundButtonType = EMusicalChairsButtonType(FMath::RandRange(0, 3));
			
			NetDecideButtonType(RoundButtonType);
			NetDecidePlayingDuration(CurrentPlayingDuration);
		}
	
		MinigameComp.StartCountDown();
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountdownFinished");

		bMayIsReady = false;
		bCodyIsReady = false;

		MayAttachComp.AttachTo(Game::GetMay().RootComponent, NAME_None, EAttachLocation::SnapToTarget);
		CodyAttachComp.AttachTo(Game::GetCody().RootComponent, NAME_None, EAttachLocation::SnapToTarget);
	}

	UFUNCTION()
	void CountdownFinished()
	{
		bCountDownFinished = true;
		bSongIsStopped = false;
		OnMusicalChairsMusicStarted.Broadcast();
	}
	

	UFUNCTION()
	void PlayerPressedButton(AHazePlayerCharacter Player, EMusicalChairsButtonType ButtonPressed)
	{
		bool bWon = false;	

		if(bSongIsStopped)
		{
			bWon = DidPlayerWin(ButtonPressed, Player);		
			
			if(bWon)
			{
				if(RoundButtonType == EMusicalChairsButtonType::TopFaceButton || RoundButtonType == EMusicalChairsButtonType::RightFaceButton)
					MinigameMaySideInteraction.StartActivating(Player);
				else
					MinigameCodySideInteraction.StartActivating(Player);
			}
			else
			{	
				WinState = CheckWinState(ButtonPressed, Player);
				NetRequestRoundWinner(WinState);
			}
		}
		else
		{
			WinState = Player.IsMay() ? EMusicalChairsRoundWinState::MayLost : EMusicalChairsRoundWinState::CodyLost;
			NetRequestRoundWinner(WinState);
		}
	}

	UFUNCTION()
	void AddScoreToMay()
	{
		GameScoreData.MayScore++;
		MinigameComp.SetScore(Game::GetMay(), GameScoreData.MayScore);
	}

	UFUNCTION()
	void AddScoreToCody()
	{
		GameScoreData.CodyScore++;
		MinigameComp.SetScore(Game::GetCody(), GameScoreData.CodyScore);
	}

	UFUNCTION(NetFunction)
	void NetRequestRoundWinner(EMusicalChairsRoundWinState NewWinState)
	{
		if (!HasControl())
			return;

		if (bRoundOver)
			return;

		NetDecideRoundWinner(NewWinState);
	}
	
	UFUNCTION(NetFunction)
	void NetDecideRoundWinner(EMusicalChairsRoundWinState NewWinState)
	{
		WinState = NewWinState;
		bRoundOver = true;
	}

	UFUNCTION()
	void WinnerReachedSeat()
	{
		bWinnerReachedSeat = true;
	}

	UFUNCTION()
	void PlayerFinishedAnimations(AHazePlayerCharacter Player)
	{		
		if(Player.IsMay())
		{
			bMayFinishedAnimations = true;
		}
		if(Player.IsCody())
		{
			bCodyFinishedAnimations = true;
		}
	}

	UFUNCTION()
	void GameOver()
	{
		bGameOver = true;
	}

	UFUNCTION()
	void ResetMusicalChairs()
	{
		if(MayAttachComp.IsAttachedTo(Game::GetMay()))
			MayAttachComp.DetachFromParent(false, false);

		if(CodyAttachComp.IsAttachedTo(Game::GetCody()))
			CodyAttachComp.DetachFromParent(false, false);


		DoubleInteractActor.EnableActor(this);
		
		bSongIsStopped = true;
		bMiniGameIsOn = false;
		bGameOver = false;
		bFinishedTutorial = false;
		bWinnerReachedSeat = false;

		bMayFinishedAnimations = false;
		bCodyFinishedAnimations = false;

		bRoundEnded = false;
		
		PlayerOnChair = nullptr;
		bRoundOver = false;
		bCountDownFinished = false;
		
		RoundNumber = 0;
		GameScoreData.MayScore = 0;
		GameScoreData.CodyScore = 0;

		FullscreenedPlayer = nullptr;

		if(Game::GetMay().IsPlayingAnyAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
			Game::GetMay().StopAllSlotAnimations();

		if(Game::GetCody().IsPlayingAnyAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
			Game::GetCody().StopAllSlotAnimations();


		Game::GetMay().DeactivateCamera(MinigameCamera);
		Game::GetCody().DeactivateCamera(MinigameCamera);

		Game::GetMay().EnableOutlineByInstigator(this);
		Game::GetCody().EnableOutlineByInstigator(this);

		Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Normal);

		MinigameComp.ResetScoreBoth();

		//RotationRoot.SetRelativeRotation(FRotator::ZeroRotator);
		//SyncedRotationComp.Value = FRotator::ZeroRotator;
	}

	UFUNCTION()
	void AddPlayerToMusicalChairs(AHazePlayerCharacter Player)
	{
		InitMusicalChairsComp(Player, this);

		bool HasMusicalChairsCapabilities = Player.IsMay() ? bMayCapabilitiesAdded : bCodyCapabilitiesAdded;

		if(!HasMusicalChairsCapabilities)
		{
			Player.AddCapability(n"MusicalChairsEnterCapability");
			Player.AddCapability(n"MusicalChairsRunningCapability");
			Player.AddCapability(n"MusicalChairsPlayerRoundEndedCapability");
			Player.AddCapability(n"MusicalChairsPlayerScoreCapability");
			Player.AddCapability(n"MusicalChairsAnimationCapability");

			if(Player.IsMay())
				bMayCapabilitiesAdded = true;
			else
				bCodyCapabilitiesAdded = true;
		}

		if(bTutorialWasCancelled)
			bTutorialWasCancelled = false;	

		Player.SetCapabilityActionState(n"ReadyForMusicalChairs", EHazeActionState::Active);
	}

	UFUNCTION()
	void PlayFailEffect()
	{
		FailEffect.Activate();
	}

	UFUNCTION()
	void StopFailEffect()
	{
		FailEffect.Deactivate();
	}

}
enum EMusicalChairsRoundWinState
{  
	MayWon,
	CodyWon,
	MayLost,
	CodyLost
};

enum EMusicalChairsButtonType
{
	TopFaceButton,
	RightFaceButton,
	LeftFaceButton,
	BottomFaceButton
};