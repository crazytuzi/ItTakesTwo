import Vino.MinigameScore.MinigameComp;
import Vino.Interactions.InteractionComponent;
import Vino.Audio.Music.MusicManagerActor;
import Rice.Audio.MinigameMusicProgressionDataAsset;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

enum EMinigameMusicTransitionType
{
	None,
	OnTutorialStart,
	OnCountdownStart,
	OnGameStart
}

enum EMiniGameMixStateDuckingType
{
	None,
	Low,
	Medium,
	High
}

enum EMiniGameMusicGenres
{
	Race,
	Pointscore,
	CountDown,
	Puzzle,
	KeepLevel,
	Unique
}

struct FMiniGameMusicData
{
	UPROPERTY()
	UAkAudioEvent StartMusicEvent = nullptr;

	UPROPERTY()
	UAkAudioEvent StopMusicEvent = nullptr;

	UPROPERTY()
	FString OnStartStinger = "";
	
	UPROPERTY()
	FString OnStopStinger = "";
	
	UPROPERTY()
	FString OnPointGetStinger = "";	
		
	UPROPERTY()
	FString OnLeaderChangeStinger = "";	
}

struct FMinigameUISoundsData
{
	UPROPERTY(Category = "Discovery HUD")
	UAkAudioEvent OnMingameDiscoveredShowHudEvent;
	UPROPERTY(Category = "Discovery HUD")
	UAkAudioEvent OnMingameDiscoveredShowName;
	UPROPERTY(Category = "Discovery HUD")
	UAkAudioEvent OnMingameDiscoveredTextFadeout;
	UPROPERTY(Category = "Discovery HUD")
	UAkAudioEvent OnMingameDiscoveredHudMoveEvent;
	UPROPERTY(Category = "Interaction")
	UAkAudioEvent OnPlayerJoinEvent;
	UPROPERTY(Category = "Interaction")
	UAkAudioEvent OnTutorialScreenEvent;
	UPROPERTY(Category = "Interaction")
	UAkAudioEvent OnTutorialPlayerConfirmEvent;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnStartCountdownEvent;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToStart3Event;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToStart2Event;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToStart1Event;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToStartFinishedEvent;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToEndEvent;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToEnd3Event;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToEnd2Event;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToEnd1Event;
	UPROPERTY(Category = "Countdown")
	UAkAudioEvent OnCountdownToEndFinishedEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnShowScoreBoxesEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnHideScoreBoxesEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnMayScorePointEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnCodyScorePointEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnMayLoosePointEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnCodyLoosePointEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnWinScreenEvent;
	UPROPERTY(Category = "Score")
	UAkAudioEvent OnWinScreenFadeoutEvent;
}

struct FMinigameMusicGenreData
{
	UPROPERTY(EditDefaultsOnly)
	FMiniGameMusicData RaceMusicData;

	UPROPERTY(EditDefaultsOnly)
	FMiniGameMusicData CountdownMusicData;

	UPROPERTY(EditDefaultsOnly)
	FMiniGameMusicData PuzzleMusicData;
	
	UPROPERTY(EditDefaultsOnly)
	FMiniGameMusicData PointScoreMusicData;
}

class UMinigameAudioComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UMinigameComp MiniGameComp;
	TArray<UInteractionComponent> InteractionComps;

	UPROPERTY(EditInstanceOnly)
	EMiniGameMusicGenres MusicType;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "MusicType == EMiniGameMusicGenres::Unique"))
	FMiniGameMusicData UniqueMusicData;

	UPROPERTY()
	EMinigameMusicTransitionType MusicTransitionType = EMinigameMusicTransitionType::OnGameStart;

	UPROPERTY(EditInstanceOnly)
	EMiniGameMixStateDuckingType MixDuckingAmount;

	UPROPERTY()
	UMinigameMusicProgressionDataAsset MusicProgressionAsset;

	UPROPERTY(EditInstanceOnly)
	bool bPlayOnScoreAudio = true;

	UPROPERTY(EditDefaultsOnly)
	FMinigameUISoundsData UISounds;

	UPROPERTY(EditDefaultsOnly)
	FMinigameMusicGenreData MusicGenreDatas;

	AHazeActor HazeOwner;
	UHazeAkComponent MiniGameHazeAkComp;
	AMusicManagerActor MusicManagerActor;
	UHazeAudioManager AudioManager;
	AHazePlayerCharacter CurrentLeader;
	float CurrentLeaderScore;
	float LastMayScore;
	float LastCodyScore;

	FHazeAudioEventInstance MinigameMusicEventInstance;
	FHazeAudioEventInstance GameplayMusicEventInstance;
	int32 PreviousMixStateId;
	int32 GameplayStateGroupId;
	int32 MusicMiniGamesStateGroupId;
	int32 MinigamesMusicDefaultStateId;
	private TArray<FName> MixStateNames;
	private bool bWasStarted = false;
	private bool bDidOverrideState = false;
	private bool bHasStartedMusic = false;
	private bool bHasUnblockedCapabilities = true;
	private float TimeSinceLeaderChanged = 0.f;

	FMiniGameMusicData MusicData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MiniGameComp = UMinigameComp::Get(Owner);
		if(MiniGameComp == nullptr)
			return;		

		AudioManager = GetAudioManager();
		MiniGameHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		MusicManagerActor = GetCurrentMusicManagerActor();

		Owner.GetComponentsByClass(UInteractionComponent::StaticClass(), InteractionComps);
		for(UInteractionComponent& InterComp : InteractionComps)
		{
			InterComp.OnActivated.AddUFunction(this, n"HandleOnInteraction");
		}

		MusicData = GetMusicData();

		MiniGameComp.OnMinigameDiscovered.AddUFunction(this, n"OnMinigameDiscovered");
		MiniGameComp.OnMinigameTutorialStarted.AddUFunction(this, n"OnTutorialStarted");
		MiniGameComp.OnTutorialPlayerReady.AddUFunction(this, n"OnTutorialPlayerReady");
		MiniGameComp.OnCountdownStartedEvent.AddUFunction(this, n"OnCountdownStarted");
		MiniGameComp.OnShowHideScoreBoxes.AddUFunction(this, n"OnShowHideScoreBoxes");
		MiniGameComp.OnMinigameStarted.AddUFunction(this, n"OnMinigameStart");
		MiniGameComp.OnTutorialCancel.AddUFunction(this, n"OnMinigameEnd");
		MiniGameComp.OnMinigamePlayerLeftEvent.AddUFunction(this, n"OnPlayerLeftArea");
		MiniGameComp.OnHideGameHUD.AddUFunction(this, n"OnHideGameHUD");
		MiniGameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"OnVictoryScreenFinished");
		
		if(bPlayOnScoreAudio)
			MiniGameComp.OnScoreChangeEvent.AddUFunction(this, n"OnScoreChanged");

		MiniGameComp.OnMiniGameShowWinner.AddUFunction(this, n"OnMiniGameComplete");

		MixStateNames.Add(HazeAudio::STATES::MinigameLowDucking);
		MixStateNames.Add(HazeAudio::STATES::MinigameMedDucking);
		MixStateNames.Add(HazeAudio::STATES::MinigameHighDucking);

		Audio::GetAkIdFromString(HazeAudio::STATES::MusicSideContentMiniGamesStateGroup.ToString(), MusicMiniGamesStateGroupId);
		Audio::GetAkIdFromString(HazeAudio::STATES::GameplayStateGroup.ToString(), GameplayStateGroupId);
	}

	UFUNCTION()
	void OnMinigameDiscovered()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnMingameDiscoveredShowHudEvent);
		System::SetTimer(this, n"HandleShowMiniGameName", 0.5f, false);
		System::SetTimer(this, n"HandleDiscoveredTextFadeout", 2.f, false);
		System::SetTimer(this, n"HandleDiscoveredHudMove", 3.f, false);
	}

	UFUNCTION()
	void HandleShowMiniGameName()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnMingameDiscoveredShowName);
	}

	UFUNCTION()
	void HandleDiscoveredTextFadeout()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnMingameDiscoveredTextFadeout);
	}	

	UFUNCTION()
	void HandleDiscoveredHudMove()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnMingameDiscoveredHudMoveEvent);
	}

	UFUNCTION()
	void HandleOnInteraction(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		if(MiniGameComp.ScoreHud != nullptr && MiniGameComp.ScoreHud.IsVisible())
		{
			Player.PlayerHazeAkComp.HazePostEvent(UISounds.OnPlayerJoinEvent);
		}
	}

	UFUNCTION()
	void OnTutorialStarted()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnTutorialScreenEvent);
		if(MusicTransitionType == EMinigameMusicTransitionType::OnTutorialStart)
			TransitionMusic(true);
	}

	UFUNCTION()
	void OnTutorialPlayerReady(AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(UISounds.OnTutorialPlayerConfirmEvent);
	}

	UFUNCTION()
	void OnCountdownStarted()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnStartCountdownEvent);		

		System::SetTimer(this, n"HandleStartCountdown3", 3.f, false);
		System::SetTimer(this, n"HandleStartCountdown2", 4.f, false);
		System::SetTimer(this, n"HandleStartCountdown1", 5.f, false);
		System::SetTimer(this, n"HandleStartCountdownFinished", 6.f, false);		

		OnMinigameStartByCountdown();
	}

	UFUNCTION()
	void HandleStartCountdown3()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnCountdownToStart3Event);
	}

	UFUNCTION()
	void HandleStartCountdown2()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnCountdownToStart2Event);
	}

	UFUNCTION()
	void HandleStartCountdown1()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnCountdownToStart1Event);
	}

	UFUNCTION()
	void HandleStartCountdownFinished()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnCountdownToStartFinishedEvent);
	}

	UFUNCTION()
	void OnShowHideScoreBoxes(bool bShouldShow)
	{
		UAkAudioEvent WantedEvent = bShouldShow ? UISounds.OnShowScoreBoxesEvent : UISounds.OnHideScoreBoxesEvent;
		MiniGameHazeAkComp.HazePostEvent(WantedEvent);
	}

	UFUNCTION()
	void OnVictoryScreenFinished()
	{
		UnblockCapabilities();
	}

	void BlockCapabilities()
	{				
		// Apperantly some minigames do fading in fullscreen, which would trigger unwanted GameOver-logic for audio. Block those capabilities here.
		if (!bHasUnblockedCapabilities)
			return;

		bHasUnblockedCapabilities = false;
		for(AHazePlayerCharacter& Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(n"GameOverAudio", this);
		}
	}

	void UnblockCapabilities()
	{
		if (bHasUnblockedCapabilities)
			return;

		bHasUnblockedCapabilities = true;
		for(AHazePlayerCharacter& Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(n"GameOverAudio", this);
		}
	}	

	UFUNCTION()
	void OnPlayerLeftArea(AHazePlayerCharacter Player)
	{
		if(MiniGameComp.PlayersInRange > 0)
			return;

		OnMinigameEnd();
	}

	UFUNCTION()
	void OnMinigameStart()
	{
		SetComponentTickEnabled(true);
		BlockCapabilities();

		if(bWasStarted)
		{
			if(MusicTransitionType == EMinigameMusicTransitionType::OnGameStart)
				TransitionMusic(true);

			return;
		}

		MusicManagerActor = GetCurrentMusicManagerActor();
		if(MusicManagerActor != nullptr)
		{
			bWasStarted = true;
			if(MusicData.OnStartStinger != "")
				MusicManagerActor.HazePostMusicStinger(MusicData.OnStartStinger);

			SetOverrideMixState(true);

			if(MusicTransitionType == EMinigameMusicTransitionType::OnGameStart)
				TransitionMusic(true);
		}

		if(MusicProgressionAsset != nullptr)
		{
			for(auto& MusicProgression : MusicProgressionAsset.MusicProgressionDatas)
			{
				MusicProgression.LastWantedMusicProgressionValue = 0.f;
				MusicProgression.bCanTrigger = true;
			}
		}
	}

	UFUNCTION()
	void OnMinigameStartByCountdown()
	{
		if(bWasStarted)
			return;

		MusicManagerActor = GetCurrentMusicManagerActor();
		if(MusicManagerActor != nullptr)
		{
			bWasStarted = true;
			if(MusicData.OnStartStinger != "")
				MusicManagerActor.HazePostMusicStinger(MusicData.OnStartStinger);

			SetOverrideMixState(true);
			
			if(MusicTransitionType == EMinigameMusicTransitionType::OnCountdownStart)
				TransitionMusic(true);
		}
	}

	UFUNCTION()
	void OnMinigameEnd()
	{
		if(bWasStarted)
		{
			TransitionMusic(false);
			SetOverrideMixState(false);
			bWasStarted = false;
		}
		else if(bHasStartedMusic)
			TransitionMusic(false);

		SetComponentTickEnabled(false);
	}

	UFUNCTION()
	void OnHideGameHUD()
	{
		OnMinigameEnd();		
	}

	int GetCallbackMask(bool bResumingGameplay)
	{
		if (bResumingGameplay)
		{
			return MusicManagerActor.bActivateMusicCallbacks ? MusicManagerActor.GetCallbackMaskForMusicCallbacks() : 0;
		}

		if (MiniGameComp.MinigameTag == EMinigameTag::BirdStar ||
			MiniGameComp.MinigameTag == EMinigameTag::MusicalChairs)
		{
			return MusicManagerActor.GetCallbackMaskForMusicCallbacks();
		}

		return 0;
	}
	
	void TransitionMusic(bool bIsStarting)
	{
		if(MusicType == EMiniGameMusicGenres::KeepLevel || (bIsStarting && bHasStartedMusic))
			return;

		MusicManagerActor = GetCurrentMusicManagerActor();
		if(MusicManagerActor == nullptr)
		{
			devEnsure(false, "Current world is missing MusicManagerActor! MiniGameAudioComponent will fail to transition music");
			return;
		}

		if(bIsStarting)
		{
			int32 CurrentFadeOut = 0;
			EAkCurveInterpolation CurrentFadeoutCurve = EAkCurveInterpolation::Exp1;
			AudioManager.GetActiveMusicEventInstance(GameplayMusicEventInstance, CurrentFadeOut, CurrentFadeoutCurve);
			MusicManagerActor.HazeStopMusicEvent(MusicManagerActor.MusicAkComponent, GameplayMusicEventInstance.PlayingID, CurrentFadeOut, CurrentFadeoutCurve);

			MinigameMusicEventInstance = MusicManagerActor.HazePostMusicEvent(MusicData.StartMusicEvent, MusicManagerActor.MusicAkComponent, MusicManagerActor, GetCallbackMask(false));
			AudioManager.SetActiveMusicEventInstance(MinigameMusicEventInstance, MusicManagerActor.FadeOutTimeMs, MusicManagerActor.FadeOutCurve);
			bHasStartedMusic = true;

			if(MusicData.OnStartStinger != "")
				MusicManagerActor.HazePostMusicStinger(MusicData.OnStartStinger);
		}
		else
		{
			MusicManagerActor.HazePostMusicEvent(MusicData.StopMusicEvent, MusicManagerActor.MusicAkComponent, MusicManagerActor, GetCallbackMask(false));
			GameplayMusicEventInstance = MusicManagerActor.HazePostMusicEvent(MusicManagerActor.MusicEvent, MusicManagerActor.MusicAkComponent, MusicManagerActor, GetCallbackMask(true));
			AudioManager.SetActiveMusicEventInstance(GameplayMusicEventInstance, MusicManagerActor.FadeOutTimeMs, MusicManagerActor.FadeOutCurve);
			bHasStartedMusic = false;
		}
	}

	UFUNCTION()
	void OnScoreChanged(AHazePlayerCharacter Player, float Score)
	{
		UAkAudioEvent WantedScoreEvent;
		bool bScoreIncrease = true;
		float PlayerScore = MiniGameComp.GetCodyScore();

		if(Player.IsMay())
		{
			PlayerScore = MiniGameComp.GetMayScore();
			if(PlayerScore > LastMayScore)
				WantedScoreEvent = UISounds.OnMayScorePointEvent;
			else
			{
				WantedScoreEvent = UISounds.OnMayLoosePointEvent;
				bScoreIncrease = false;
			}	
		}
		else if(PlayerScore > LastCodyScore)
			WantedScoreEvent = UISounds.OnCodyScorePointEvent;
		else
		{
			WantedScoreEvent = UISounds.OnCodyLoosePointEvent;		
			bScoreIncrease = false;
		}

		Player.PlayerHazeAkComp.HazePostEvent(WantedScoreEvent);

		if(MusicManagerActor != nullptr)
		{
			if(bScoreIncrease && MusicData.OnPointGetStinger != "" && MusicProgressionAsset != nullptr)
				if(MusicProgressionAsset.OnPointGetStingerIncrements.Num() == 0 || MusicProgressionAsset.OnPointGetStingerIncrements.Contains(PlayerScore))
					MusicManagerActor.HazePostMusicStinger(MusicData.OnPointGetStinger);
		}


		if(PlayerScore > CurrentLeaderScore && Player != CurrentLeader)
			OnLeaderChanged(Player);
		else if(Player == CurrentLeader)
			CurrentLeaderScore = PlayerScore;
	}

	void OnLeaderChanged(AHazePlayerCharacter NewLeader)
	{
		if(MusicProgressionAsset == nullptr)
			return;
			
		if(MusicManagerActor != nullptr)
		{		
			if(MusicData.OnLeaderChangeStinger != "" && TimeSinceLeaderChanged >= MusicProgressionAsset.OnLeaderChangeStingerCooldown)
				MusicManagerActor.HazePostMusicStinger(MusicData.OnLeaderChangeStinger);	
		}
	}

	UFUNCTION()
	void OnMiniGameComplete()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnWinScreenEvent);

		if(MusicManagerActor != nullptr)
		{
			if(MusicData.OnStopStinger != "")
				MusicManagerActor.HazePostMusicStinger(MusicData.OnStopStinger);
		}

		System::SetTimer(this, n"HandleWinnerHUDFadeout", 4.f, false);
		OnMinigameEnd();
	}

	UFUNCTION()
	void HandleWinnerHUDFadeout()
	{
		MiniGameHazeAkComp.HazePostEvent(UISounds.OnWinScreenFadeoutEvent);
	}

	void SetOverrideMixState(bool bIsStarting)
	{		
		if(MixDuckingAmount == EMiniGameMixStateDuckingType::None)
			return;

		if(bIsStarting)
		{			
			Audio::GetStateGroupsCurrentState(HazeAudio::STATES::GameplayStateGroup, PreviousMixStateId);

			int32 MinigameMixStateId = -1;
			FString MixStateName = "";

			GetMixStateNameAsString(MixStateName);
			Audio::GetAkIdFromString(MixStateName, MinigameMixStateId);
			Audio::SetAkStateById(GameplayStateGroupId, MinigameMixStateId);
			bDidOverrideState = true;
		}
		else
		{
			Audio::SetAkStateById(GameplayStateGroupId, PreviousMixStateId);	
			if(MusicProgressionAsset != nullptr && MusicProgressionAsset.MusicProgressionDatas.Num() > 0)
			{
				Audio::GetAkIdFromString(HazeAudio::STATES::MusicSideContentMiniGamesDefaultState.ToString(), MinigamesMusicDefaultStateId);
				Audio::SetAkStateById(MusicMiniGamesStateGroupId, MinigamesMusicDefaultStateId);
			}

			bDidOverrideState = false;
		}			
	}

	FMiniGameMusicData GetMusicData()
	{
		switch(MusicType)
		{
			case(EMiniGameMusicGenres::KeepLevel):
				return FMiniGameMusicData();

			case(EMiniGameMusicGenres::Unique):
				return UniqueMusicData;

			case(EMiniGameMusicGenres::Race):
				return MusicGenreDatas.RaceMusicData;

			case(EMiniGameMusicGenres::CountDown):
				return MusicGenreDatas.CountdownMusicData;

			case(EMiniGameMusicGenres::Pointscore):
				return MusicGenreDatas.PointScoreMusicData;

			case(EMiniGameMusicGenres::Puzzle):
				return MusicGenreDatas.PuzzleMusicData;	
		}

		return FMiniGameMusicData();
	}

	void GetMixStateNameAsString(FString &OutName)
	{
		int32 MixDuckingValue = int(MixDuckingAmount) - 1;
		if(MixDuckingValue < 0)
			MixDuckingValue = 0;

		OutName = MixStateNames[MixDuckingValue].ToString();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		QueryMusicProgression();
		TimeSinceLeaderChanged += DeltaSeconds;
	}

	void QueryMusicProgression()
	{		
		if(MusicProgressionAsset == nullptr)
			return;

		for(FMinigameMusicProgressionData& MusicProgression : MusicProgressionAsset.MusicProgressionDatas)
		{
			float WantedProgressionTriggerValue;
			if(MusicProgression.ProgressionType == EMiniGameMusicProgressionType::Score)
				WantedProgressionTriggerValue = FMath::Max(MiniGameComp.ScoreData.CodyScore, MiniGameComp.ScoreData.MayScore);
			else
				WantedProgressionTriggerValue = MiniGameComp.CurrentTimer;

			if(MusicProgressionValueWasMet(MusicProgression, WantedProgressionTriggerValue))
			{
				if(MusicProgression.ProgressionTriggerType == EMiniGameMusicProgressionTriggerType::State)
				{
					int32 MusicProgressionStateId = -1;
					Audio::GetAkIdFromString(MusicProgression.MusicProgressionStateTrigger, MusicProgressionStateId);

					Audio::SetAkStateById(MusicMiniGamesStateGroupId, MusicProgressionStateId);
				}
				else if(MusicManagerActor != nullptr)
				{
					MusicManagerActor.HazePostMusicStinger(MusicProgression.MusicProgressionStateTrigger);
				}

				if(MusicProgression.bTriggerOnce)
					MusicProgression.bCanTrigger = false;
			}

			MusicProgression.LastWantedMusicProgressionValue = WantedProgressionTriggerValue;
		}
	}

	bool MusicProgressionValueWasMet(FMinigameMusicProgressionData& MusicProgression, const float WantedMusicProgressionValue)
	{
		bool bConditionMet = false;
		if(MusicProgression.ProgressionType == EMiniGameMusicProgressionType::TimeCountDown)
		{
			if(MusicProgression.LastWantedMusicProgressionValue > MusicProgression.ProgressionValue && WantedMusicProgressionValue <= MusicProgression.ProgressionValue)
				bConditionMet = true;
		}
		else
		{
			if(MusicProgression.LastWantedMusicProgressionValue < MusicProgression.ProgressionValue && WantedMusicProgressionValue >= MusicProgression.ProgressionValue)
				bConditionMet = true;
		}

		return (bConditionMet && MusicProgression.bCanTrigger);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		// Handle exit if Minigame was never actually completed
		if(bWasStarted)
		{
			OnMinigameEnd();
			if(!bHasUnblockedCapabilities)
				UnblockCapabilities();
		}
	}

	AMusicManagerActor GetCurrentMusicManagerActor()
	{
		if(MusicManagerActor != nullptr)
			return MusicManagerActor;
		
		return Cast<AMusicManagerActor>(UHazeAkComponent::GetMusicManagerActor());
	}
}