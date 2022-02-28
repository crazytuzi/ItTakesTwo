import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceSnailActor;
import Vino.Interactions.DoubleInteractionActor;
import Vino.MinigameScore.ScoreHud;
import Peanuts.Triggers.ActorTrigger;
import Peanuts.Position.TransformActor;
import Peanuts.Fades.FadeStatics;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceMushroomActor;

event void FSnailgateStateChangedEventSignature();
class ASnailRaceHandlerActor : AHazeActor
{
	UPROPERTY(Category = "SnailgameEvents")
	FSnailgateStateChangedEventSignature OnGameStarted;

	UPROPERTY(Category = "SnailgameEvents")
	FSnailgateStateChangedEventSignature OnGameReset;

	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Icon;

	UPROPERTY()
	ASnailRaceSnailActor Snail01;
	
	UPROPERTY()
	TArray<ASnailRaceMushroomActor> MushRooms;

	UPROPERTY()
	ASnailRaceSnailActor Snail02;

	UPROPERTY()
	ADoubleInteractionActor StartInteraction;
	
	UPROPERTY()
	AKeepInViewCameraActor KeepInViewCamera;

	UPROPERTY()
	AActorTrigger FinishlineTrigger;

	UPROPERTY()
	ATransformActor Snail01StartPos;

	UPROPERTY()
	ATransformActor Snail02StartPos;

	UPROPERTY()
	ATransformActor Player01StartPos;

	UPROPERTY()
	ATransformActor Player02StartPos;

	UPROPERTY()
	ATransformActor Player01JumpoffPos;

	UPROPERTY()
	ATransformActor Player02JumpoffPos;

	UPROPERTY()
	AHazeCameraActor WinCam;

    default MinigameComp.ScoreData.ShowTimer = true;
    default MinigameComp.ScoreData.ShowHighScore = false;
	default MinigameComp.ScoreData.ShowScoreBoxes = false;
	default MinigameComp.ScoreData.ShowHighScore = true;

	UPROPERTY(DefaultComponent, ShowOnActor)
    UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::SnailRace;
	
	// UScoreHud ScoreHud;

	float RoundTime;
	bool bRunningGame = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartInteraction.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteract");

		StartInteraction.LeftInteraction.AttachToComponent(Snail01.Body, n"SnailRaceAttach", AttachmentRule = EAttachmentRule::SnapToTarget);
		StartInteraction.RightInteraction.AttachToComponent(Snail02.Body, n"SnailRaceAttach", AttachmentRule = EAttachmentRule::SnapToTarget);

		StartInteraction.LeftInteraction.OnActivated.AddUFunction(this, n"OnLeftActivated");
		StartInteraction.RightInteraction.OnActivated.AddUFunction(this, n"OnRightActivated");
		
		FinishlineTrigger.OnActorEnter.AddUFunction(this, n"ReachedFinishline");
		StartInteraction.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"PlayerCancelled");

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"StartRace");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"CancelFromTutorial");
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountDownFinished");

		GetAllActorsOfClass(ASnailRaceMushroomActor::StaticClass(), MushRooms);
	}

	UFUNCTION()
	void OnLeftActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(Snail01.MayJumpOnAudioEvent);
	}

	UFUNCTION()
	void OnRightActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(Snail02.CodyJumpOnAudioEvent);
	}

	UFUNCTION()
	void PlayerCancelled(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		FHazeJumpToData Data;

		if (bIsLeftInteraction)
		{
			Data.TargetComponent = Player01JumpoffPos.Root;
			JumpTo::ActivateJumpTo(Player, Data);
		}
		else
		{
			Data.TargetComponent = Player02JumpoffPos.Root;
			JumpTo::ActivateJumpTo(Player, Data);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnDoubleInteract()
	{
		for (auto Player : Game::GetPlayers())
		{
			if (Player.IsCody())
			{
				Player.PlaySlotAnimation(Animation = StartInteraction.CodyLeftAnimations.MH, bLoop = true);
			}
			
			else
			{
				Player.PlaySlotAnimation(Animation = StartInteraction.MayLeftAnimations.MH, bLoop = true);
			}

		}

		MinigameComp.ActivateTutorial();
		StartInteraction.Disable(n"BothPlayersRiding");
	}

	UFUNCTION()
	void CancelFromTutorial()
	{
		for (auto Player : Game::GetPlayers())
		{
			FHazeJumpToData Data;

			if (Player.IsCody())
			{
				Data.TargetComponent = Player02JumpoffPos.Root;
				JumpTo::ActivateJumpTo(Player, Data);
			}

			else
			{
				Data.TargetComponent = Player01JumpoffPos.Root;
				JumpTo::ActivateJumpTo(Player, Data);
			}

			Player.StopAllSlotAnimations();
		}

		StartInteraction.Enable(n"BothPlayersRiding");
	}

	UFUNCTION(NotBlueprintCallable)
	void StartRace()
	{
		for (auto Player : Game::GetPlayers())
		{
			Player.StopAllSlotAnimations();
		}

		for (auto i : MushRooms)
		{
			i.HazeAkComp.HazePostEvent(i.StartMoveAudioEvent);
			i.EnableActor(nullptr);
		}

		Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);

		KeepInViewCamera.ActivateCamera(Game::GetCody(), CameraBlend::Normal(), this, EHazeCameraPriority::Script);
		RoundTime = 0;

		// MinigameComp.SetCountdownFinishedText(CountDownText);
		MinigameComp.StartCountDown();

		OnGameStarted.Broadcast();

		if(Snail01.HasControl())
		{
			Snail01.StartRidingSnail(Game::GetMay());
		}
		
		if (Snail02.HasControl())
		{
			Snail02.StartRidingSnail(Game::GetCody());
		}

		for (AHazePlayerCharacter pl : Game::GetPlayers())
		{
			pl.BlockCapabilities(CapabilityTags::MovementInput, this);
			pl.BlockCapabilities(CapabilityTags::MovementAction, this);
		}

		if (Snail01.HasControl())
		{
			Snail01.NetSetBlockSnailValue(true);
		}
		
		if (Snail02.HasControl())
		{
			Snail02.NetSetBlockSnailValue(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bRunningGame)
		{
			RoundTime += DeltaTime;
			MinigameComp.SetTimer(RoundTime);
		}
	}

	UFUNCTION()
	void CountDownFinished()
	{
		bRunningGame = true;
		Snail01.SetCapabilityActionState(n"StartSnailRace", EHazeActionState::Active);
		Snail02.SetCapabilityActionState(n"StartSnailRace", EHazeActionState::Active);

		Snail01.RidingPlayer.PlayerHazeAkComp.HazePostEvent(Snail01.StartSnailMoveAudioEvent);
		Snail02.RidingPlayer.PlayerHazeAkComp.HazePostEvent(Snail02.StartSnailMoveAudioEvent);

		if (Snail01.HasControl())
		{
			Snail01.NetSetBlockSnailValue(false);
		}
		
		if (Snail02.HasControl())
		{
			Snail02.NetSetBlockSnailValue(false);
		}

		for (AHazePlayerCharacter pl : Game::GetPlayers())
		{
			pl.UnblockCapabilities(CapabilityTags::MovementInput, this);
			pl.UnblockCapabilities(CapabilityTags::MovementAction, this);
		}
	}

	UFUNCTION()
	void ReachedFinishline(AHazeActor Actor)
	{
		if (!bRunningGame)
			return;
		
		AHazePlayerCharacter RidingPlayer;
		ASnailRaceSnailActor Snail;

		Snail = Cast<ASnailRaceSnailActor>(Actor);
		RidingPlayer = Snail.RidingPlayer;
		bRunningGame = false;

		Snail01.SetCapabilityActionState(n"StopMoving", EHazeActionState::Active);
		Snail02.SetCapabilityActionState(n"StopMoving", EHazeActionState::Active);

		PlayerReachedEnd(RidingPlayer);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerReachedEnd(AHazePlayerCharacter Player)
	{
		EMinigameWinner Winner;
		
		Snail01.Reset();
		Snail02.Reset();

		for (auto i : MushRooms)
		{
			i.HazeAkComp.HazePostEvent(i.StopMoveAudioEvent);
			i.DisableActor(nullptr);
		}

		if (Snail01.HasControl())
		{
			Snail01.NetSetBlockSnailValue(true);
		}
		
		if (Snail02.HasControl())
		{
			Snail02.NetSetBlockSnailValue(true);
		}

		if (Player == Game::GetCody())
		{
			Winner = EMinigameWinner::Cody;
		}
		else
		{
			Winner = EMinigameWinner::May;
		}


		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"StartResetGame");
		MinigameComp.SetScore(Player, MinigameComp.GetTimerValue());
		MinigameComp.AnnounceWinner(Winner);

		Snail01.RidingPlayer.PlayerHazeAkComp.HazePostEvent(Snail01.StopSnailMoveAudioEvent);
		Snail02.RidingPlayer.PlayerHazeAkComp.HazePostEvent(Snail02.StopSnailMoveAudioEvent);
		

		for (auto p : Game::GetPlayers())
		{
			WinCam.ActivateCamera(p, CameraBlend::Normal(), this);
		}

		for (auto Pl : Game::GetPlayers())
		{
			Pl.BlockCapabilities(CapabilityTags::MovementInput, this);
			Pl.BlockCapabilities(CapabilityTags::MovementAction, this);
		}
	}

	UFUNCTION()
	void StartResetGame()
	{
		FadeOutFullscreen(1, 0.5f, 1.f);
		System::SetTimer(this, n"PerformReset", 0.5, false);
	}

	UFUNCTION()
	void PerformReset()
	{
		Snail01.TeleportActor(Snail01StartPos.ActorLocation, Snail01StartPos.ActorRotation);
		Snail02.TeleportActor(Snail02StartPos.ActorLocation, Snail02StartPos.ActorRotation);

		for (auto Player : Game::GetPlayers())
		{
			WinCam.DeactivateCamera(Player, 0.f);
		}

		Snail01.RidingPlayer = nullptr;
		Snail02.RidingPlayer = nullptr;

		if (Snail01.HasControl())
		{
			Snail01.NetSetBlockSnailValue(false);
		}
		
		if (Snail02.HasControl())
		{
			Snail02.NetSetBlockSnailValue(false);
		}

		for (auto Pl : Game::GetPlayers())
		{
			Pl.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Pl.UnblockCapabilities(CapabilityTags::MovementAction, this);
		}

		for(auto player : Game::GetPlayers())
		{
			player.SetCapabilityActionState(n"StopRidingSnail", EHazeActionState::Active);
		}

		System::SetTimer(this, n"DelayedResetTeleport", 0.1f, false);

		Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Normal);

		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			KeepInViewCamera.DeactivateCamera(Player, 0.f);
		}

		OnGameReset.Broadcast();

		if(HasControl())
		{
			System::SetTimer(this, n"ResetInteractions", 2, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void DelayedResetTeleport()
	{
		Game::GetCody().TeleportActor(Player01StartPos.ActorLocation, Player01StartPos.ActorRotation);
		Game::GetMay().TeleportActor(Player02StartPos.ActorLocation, Player02StartPos.ActorRotation);
		Game::GetCody().SnapCameraBehindPlayer();
		Game::GetMay().SnapCameraBehindPlayer();
	}

	UFUNCTION(NetFunction)
	void ResetInteractions()
	{
		StartInteraction.Enable(n"BothPlayersRiding");
	}
}