import Cake.LevelSpecific.Clockwork.TimeBomb.BombRegenPoint;
import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Cake.LevelSpecific.Clockwork.TimeBomb.TimeBombFinishArea;
import Vino.MinigameScore.ScoreHud;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.Clockwork.TimeBomb.TimeBombDoubleInteract;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyManager;

event void FOnFirstTimeSequence();
event void FBombRunCheckTheHellTower(bool bEnable);

class ATimeBombGameManager : AHazeActor
{
	UPROPERTY(Category = "Events")
	FOnFirstTimeSequence OnFirstTimeSequence;

	UPROPERTY()
	FBombRunCheckTheHellTower OnBombRunCheckTheHellTower;

	//*** GENERAL SETUP ***//
	UPROPERTY(Category = "Setup")
	TArray<AActor> ArrayOutput;

	TArray<ABombRegenPoint> BombRegenPointArray;

	UPROPERTY(Category = "Setup")
	ABombRegenPoint StartingBombRegen;

	UPROPERTY(Category = "Setup")
	ATimeBombFinishArea TimeBombFinishArea;
	
	UPROPERTY(Category = "Setup")
	ATimeBombDoubleInteract TimeBombDoubleInteract;

	UPROPERTY(Category = "Setup")
	AHorseDerbyManager HorseManager;

	UPROPERTY(Category = "Setup")
	APlayerTrigger HorseDerbyPlayerTrigger1;

	UPROPERTY(Category = "Setup")
	APlayerTrigger HorseDerbyPlayerTrigger2;

	UPROPERTY(Category = "Setup")
	UFoghornVOBankDataAssetBase VOGenericBank;

	AHazePlayerCharacter Winner;
	AHazePlayerCharacter Loser;

	UPROPERTY(meta = (MakeEditWidget))
	TPerPlayer<FVector> EndGameLocs;

	//*** PLAYER COMPS ***//
	UPlayerTimeBombComp PlayerCompMay;
	UPlayerTimeBombComp PlayerCompCody;

	//*** GAME STATUS ***//
	bool bGameActive;
	bool bHavePlayedSequence;
	bool bHorseManagerDisabled;

	float MinDistanceRange = 2500.f;

	// //*** MINIGAME INFO ***//
	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::BombRun;

	float MaxBombTime = 16.f; //should be 16
	float MayTime;
	float CodyTime;

	float NewLightTimeMay;
	float NewLightTimeCody;

	float RecoveryTime = 6.f;

	bool bGameTicking;
	bool bHasExploded;

	int MayRegenCount;
	int CodyRegenCount;

	int RandomPlay;
	int RMin = 1;
	int RMax = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bHavePlayedSequence = true;

		GetAllActorsOfClass(BombRegenPointArray);

		for (ABombRegenPoint RegenPoint : BombRegenPointArray)
		{
			RegenPoint.OnTimeIncreased.AddUFunction(this, n"IncreaseTime");

			if (HasControl())
				DisableBombRegenPoint(RegenPoint);

			RegenPoint.EventDisableRegenPoint.AddUFunction(this, n"DisableBombRegenPoint");
		}

		TimeBombDoubleInteract.LeftInteraction.OnActivated.AddUFunction(this, n"VOInteractCheck");
		TimeBombDoubleInteract.RightInteraction.OnActivated.AddUFunction(this, n"VOInteractCheck");

		TimeBombDoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"ReadyState");
		TimeBombDoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"BeginCountDown");
		
		if (HasControl())
		{
			MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"CheckSequence");
			MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"InitiateGame");
		}

		MinigameComp.OnTutorialCancel.AddUFunction(this, n"TutorialCancel");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bGameTicking)
		{
			TimeHandler(DeltaTime);
			BombLightHandler(DeltaTime);
		}
	}

	void TimeHandler(float DeltaTime)
	{
		if (!bGameActive)
			return;
		
		MayTime -= DeltaTime;
		CodyTime -= DeltaTime;

		if (MayTime < 0.f)
			MayTime = 0.f;

		if (CodyTime < 0.f)
			CodyTime = 0.f;

		MinigameComp.UpdateDoubleTime(MayTime, Game::May);
		MinigameComp.UpdateDoubleTime(CodyTime, Game::Cody);

		if (!HasControl())
			return;

		if (bHasExploded)
			return;

		if (MayTime <= 0.f && CodyTime > 0.f)
			PlayerLoses(Game::May);
		else if (CodyTime <= 0.f && MayTime > 0.f)
			PlayerLoses(Game::Cody);
		else if (MayTime <= 0.f && CodyTime <= 0.f)
			PlayersDraw();
	}

	void BombLightHandler(float DeltaTime)
	{
		float MinTime1 = 0.f;

		if (PlayerCompMay != nullptr)
		{
			if (MayTime <= MaxBombTime && MayTime >= 10.f)
				PlayerCompMay.CountDownSetter(3);
			else if (MayTime < 10.f && MayTime >= 6.f)
				PlayerCompMay.CountDownSetter(2);
			else if (MayTime < 6.f && MayTime >= 3.f)
				PlayerCompMay.CountDownSetter(1);
			else if (MayTime < 3.f)
				PlayerCompMay.CountDownSetter(0);

			if (NewLightTimeMay <= System::GameTimeInSeconds && PlayerCompMay.BombMesh != nullptr)
			{
				NewLightTimeMay = System::GameTimeInSeconds + PlayerCompMay.LightRate;
				PlayerCompMay.BombMesh.ActivateLight(PlayerCompMay.LightRate * 0.6f);

				if (MayTime <= MaxBombTime && MayTime >= 10.f)
					PlayerCompMay.AudioBeepTime(1);
				else if (MayTime < 10.f && MayTime >= 6.f)
					PlayerCompMay.AudioBeepTime(2);
				else if (MayTime < 6.f && MayTime >= 3.f)
					PlayerCompMay.AudioBeepTime(3);
				else if (MayTime < 3.f)
					PlayerCompMay.AudioBeepTime(4);
			}
		}

		if (PlayerCompCody != nullptr)
		{
			if (CodyTime <= MaxBombTime && CodyTime >= 10.f)
				PlayerCompCody.CountDownSetter(3);
			else if (CodyTime < 10.f && CodyTime >= 6.f)
				PlayerCompCody.CountDownSetter(2);
			else if (CodyTime < 6.f && CodyTime >= 3.f)
				PlayerCompCody.CountDownSetter(1);
			else if (CodyTime < 3.f)
				PlayerCompCody.CountDownSetter(0);

			if (NewLightTimeCody <= System::GameTimeInSeconds && PlayerCompCody.BombMesh != nullptr)
			{
				NewLightTimeCody = System::GameTimeInSeconds + PlayerCompCody.LightRate;
				PlayerCompCody.BombMesh.ActivateLight(PlayerCompCody.LightRate * 0.6f);

				if (CodyTime <= MaxBombTime && CodyTime >= 10.f)
					PlayerCompCody.AudioBeepTime(1);
				else if (CodyTime < 10.f && CodyTime >= 6.f)
					PlayerCompCody.AudioBeepTime(2);
				else if (CodyTime < 6.f && CodyTime >= 3.f)
					PlayerCompCody.AudioBeepTime(3);
				else if (CodyTime < 3.f)
					PlayerCompCody.AudioBeepTime(4);
			}
		}
	}

	UFUNCTION(NetFunction)
	void IncreaseTime(AHazePlayerCharacter Player)
	{
		RandomPlay--;

		if (RandomPlay <= 0)
		{
			RandomPlay = FMath::RandRange(RMin, RMax);
			MinigameComp.PlayTauntAllVOBark(Player);
		}

		if (Player == Game::May)
		{
			MayTime += RecoveryTime;
			MayTime = FMath::Clamp(MayTime, 0.f, MaxBombTime);

			if (MayTime <= MaxBombTime && MayTime >= 10.f)
				PlayerCompMay.CountDownSetter(3);
			else if (MayTime < 10.f && MayTime >= 6.f)
				PlayerCompMay.CountDownSetter(2);
			else if (MayTime < 6.f && MayTime >= 3.f)
				PlayerCompMay.CountDownSetter(1);
			else if (MayTime < 3.f)
				PlayerCompMay.CountDownSetter(0);

			MayRegenCount++;

			if (MayRegenCount == BombRegenPointArray.Num())
			{
				if (HasControl())
					ReachedLastRegenPoint(Player);
			}
		}
		else
		{
			CodyTime += RecoveryTime;
			CodyTime = FMath::Clamp(CodyTime, 0.f, MaxBombTime);

			if (CodyTime <= MaxBombTime && CodyTime >= 10.f)
				PlayerCompCody.CountDownSetter(3);
			else if (CodyTime < 10.f && CodyTime >= 6.f)
				PlayerCompCody.CountDownSetter(2);
			else if (CodyTime < 6.f && CodyTime >= 3.f)
				PlayerCompCody.CountDownSetter(1);
			else if (CodyTime < 3.f)
				PlayerCompCody.CountDownSetter(0);		

			CodyRegenCount++;

			if (CodyRegenCount == BombRegenPointArray.Num())
			{
				if (HasControl())
					ReachedLastRegenPoint(Player);
			}
		}
	}

	UFUNCTION(NetFunction)
	void PlayerLoses(AHazePlayerCharacter Player)
	{
		if (!bGameActive)
			return;

		bHasExploded = true;
			
		bGameActive = false;
		bGameTicking = false;
		
		UPlayerTimeBombComp CurrentPlayerComp = UPlayerTimeBombComp::Get(Player);
		UPlayerTimeBombComp OtherPlayerComp = UPlayerTimeBombComp::Get(Player.OtherPlayer);

		CurrentPlayerComp.TimeBombWinLoseState = ETimeBombWinLoseState::Lose;
		OtherPlayerComp.TimeBombWinLoseState = ETimeBombWinLoseState::Won;

		CurrentPlayerComp.TimeBombState = ETimeBombState::Explosion;
	}

	UFUNCTION(NetFunction)
	void PlayersDraw()
	{
		UPlayerTimeBombComp LosePlayerCompMay = UPlayerTimeBombComp::Get(Game::May);
		UPlayerTimeBombComp LosePlayerCompCody = UPlayerTimeBombComp::Get(Game::Cody);
		PlayerCompMay.TimeBombState = ETimeBombState::Explosion;
		PlayerCompCody.TimeBombState = ETimeBombState::Explosion;
		LosePlayerCompMay.TimeBombWinLoseState = ETimeBombWinLoseState::Draw;
		LosePlayerCompCody.TimeBombWinLoseState = ETimeBombWinLoseState::Draw;
	}

	UFUNCTION()
	void ReadyState()
	{
		MinigameComp.AddPlayerCapabilitySheets();

		PlayerCompMay = UPlayerTimeBombComp::Get(Game::GetMay());
		PlayerCompMay.TimeBombManager = this;
		PlayerCompMay.FacingDirection = TimeBombDoubleInteract.ActorForwardVector;

		PlayerCompCody = UPlayerTimeBombComp::Get(Game::GetCody());
		PlayerCompCody.TimeBombManager = this;
		PlayerCompCody.FacingDirection = TimeBombDoubleInteract.ActorForwardVector;

		PlayerCompMay.TimeBombState = ETimeBombState::Ready;
		PlayerCompCody.TimeBombState = ETimeBombState::Ready;
		
		#if EDITOR
			if(bHazeEditorOnlyDebugBool)
			{
				PlayerCompCody.MaxCountDownStage = 500;
			}
		#endif
	}

	UFUNCTION(NetFunction)
	void InitiateTimeSettings()
	{
		MayTime = MaxBombTime;
		CodyTime = MaxBombTime;
		
		MinigameComp.UpdateDoubleTime(MayTime, Game::May);
		MinigameComp.UpdateDoubleTime(CodyTime, Game::Cody);
	}

	UFUNCTION()
	void BeginCountDown()
	{
		if (!HorseManager.IsActorDisabled(this))
			HorseManager.DisableActor(this);

		HorseDerbyPlayerTrigger1.SetTriggerEnabled(false);
		HorseDerbyPlayerTrigger2.SetTriggerEnabled(false);

		MayRegenCount = 0;
		CodyRegenCount = 0;

		if (!HasControl())
			return;

		NetDisableInteractions();
		CheckTutorial();
		InitiateTimeSettings();

		OnBombRunCheckTheHellTower.Broadcast(false);
	}
	
	UFUNCTION(NetFunction)
	void CheckTutorial()
	{
		MinigameComp.ActivateTutorial();

		Game::May.BlockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		UTimeControlSequenceComponent SeqComp =  UTimeControlSequenceComponent::Get(Game::May);
		
		if (SeqComp != nullptr)
			SeqComp.DeactiveClone(Game::May);
	}

	UFUNCTION(NetFunction)
	void CheckSequence()
	{
		if (!bHavePlayedSequence)
			SequenceStarted();
		else
			StartGame();
	}

	UFUNCTION(NetFunction)
	void NetDisableInteractions()
	{
		TimeBombDoubleInteract.LeftInteraction.Disable(n"Bomb Race Started");
		TimeBombDoubleInteract.RightInteraction.Disable(n"Bomb Race Started");
	}

	UFUNCTION(NetFunction)
	void NetEnableInteractions()
	{
		TimeBombDoubleInteract.LeftInteraction.Enable(n"Bomb Race Started");
		TimeBombDoubleInteract.RightInteraction.Enable(n"Bomb Race Started");
	}

	UFUNCTION(NetFunction)
	void SequenceStarted()
	{
		for (ABombRegenPoint Regen : BombRegenPointArray)
		{
			if (HasControl())
			{
				if (Regen.IsActorDisabled())
				{
					EnableBombRegenPoint(Regen);
				}
			}
		}	

		bHavePlayedSequence = true;
		OnFirstTimeSequence.Broadcast();
	}

	UFUNCTION()
	void SequenceFinished()
	{
		if (HasControl())
			StartGame();
	}

	void UpdateMayTimer(float Value)
	{
		MinigameComp.UpdateDoubleTime(Value, Game::May);
	}

	void UpdateCodyTimer(float Value)
	{
		MinigameComp.UpdateDoubleTime(Value, Game::Cody);
	}

	UFUNCTION()
	void FadeScreensAfterSequence()
	{
		FadeOutPlayer(Game::GetMay(), 0.75f, 0.6f, 0.75f); 
		FadeOutPlayer(Game::GetCody(), 0.75f, 0.6f, 0.75f); 
	}

	UFUNCTION()
	void TutorialCancel()
	{
		MinigameComp.RemovePlayerCapabilitySheets();
		Game::May.UnblockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		
		if (HasControl())
		{
			NetEnableInteractions();
			TimeBombDoubleInteract.EndAnimationsForPlayer(Game::May);
			TimeBombDoubleInteract.EndAnimationsForPlayer(Game::Cody);
		}
	}

	UFUNCTION(NetFunction)
	void StartGame()
	{
		MinigameComp.StartCountDown();
		MinigameComp.BlockGameHudDeactivation();

		PlayerCompMay.TimeBombState = ETimeBombState::Spawned;
		PlayerCompCody.TimeBombState = ETimeBombState::Spawned;
	}

	UFUNCTION(NetFunction)
	void InitiateGame()
	{
		bGameActive = true;
		bGameTicking = true;

		TimeBombDoubleInteract.SetArrowGameStartedMode(bGameActive);

		if (HasControl())
		{
			TimeBombDoubleInteract.EndAnimationsForPlayer(Game::May);
			TimeBombDoubleInteract.EndAnimationsForPlayer(Game::Cody);
		}
		
		for (ABombRegenPoint Regen : BombRegenPointArray)
		{
			if (HasControl())
			{
				if (Regen.IsActorDisabled())
				{
					EnableBombRegenPoint(Regen);
				}

				Regen.UnlightForPlayer(Game::GetMay());
				Regen.UnlightForPlayer(Game::GetCody());
				
				Regen.ResetBools();
			}
		}	

		if (HasControl())
		{
			StartingBombRegen.LightUpForPlayer(Game::GetMay());
			StartingBombRegen.LightUpForPlayer(Game::GetCody());
		}	

		PlayerCompMay.TimeBombState = ETimeBombState::Ticking;
		PlayerCompCody.TimeBombState = ETimeBombState::Ticking;
	}

	UFUNCTION(NetFunction)
	void ManagerAnnounceDraw()
	{
		bGameActive = false;
		bGameTicking = false;
		
		TimeBombDoubleInteract.SetArrowGameStartedMode(bGameActive);
		PlayerCompMay.TimeBombState = ETimeBombState::Default;
		PlayerCompCody.TimeBombState = ETimeBombState::Default;
		MinigameComp.AnnounceWinner(EMinigameWinner::Draw);

		Winner = nullptr;
		Loser = nullptr;

		for (ABombRegenPoint Regen : BombRegenPointArray)
			Regen.Disappear();

		if (HasControl())
			System::SetTimer(this, n"GameComplete", 3.f, false);
	}

	UFUNCTION(NetFunction)
	void ManagerAnnounceWinner(AHazePlayerCharacter LosingPlayer)
	{
		TimeBombDoubleInteract.SetArrowGameStartedMode(bGameActive);

		if (LosingPlayer == Game::GetCody())
		{
			Winner = Game::May;
			Loser = Game::Cody;
		}
		else
		{
			Winner = Game::Cody;
			Loser = Game::May;
		}

		TeleportWinner();

		if (LosingPlayer == Game::GetCody())
		{
			MinigameComp.AnnounceWinner(EMinigameWinner::May);
			PlayerCompMay.TimeBombState = ETimeBombState::Default;
		}
		else
		{
			MinigameComp.AnnounceWinner(EMinigameWinner::Cody);
			PlayerCompCody.TimeBombState = ETimeBombState::Losing;
		}

		for (ABombRegenPoint Regen : BombRegenPointArray)
		{
			Regen.Disappear();
		}

		if (HasControl())
			System::SetTimer(this, n"GameComplete", 3.f, false);
	}

	UFUNCTION(NetFunction)
	void GameComplete()
	{
		bHasExploded = false;

		PlayerCompMay.TimeBombState = ETimeBombState::Default;
		PlayerCompCody.TimeBombState = ETimeBombState::Default;

		Game::May.UnblockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);

		EHazeViewPointBlendSpeed Blend;
		Blend = EHazeViewPointBlendSpeed::Slow;

		Game::May.ClearViewSizeOverride(this);
		Game::Cody.ClearViewSizeOverride(this);

		for (ABombRegenPoint Regen : BombRegenPointArray)
		{
			if (HasControl())
			{
				if (!Regen.IsActorDisabled())
				{
					DisableBombRegenPoint(Regen);
					NetEnableInteractions();
				}
			}
		}

		PlayerCompMay.bResetCamOnRespawn = true;
		PlayerCompCody.bResetCamOnRespawn = true;

		if (Winner == nullptr && Loser == nullptr)
		{
			TeleportPlayer(Game::May);
			TeleportPlayer(Game::Cody);
			MinigameComp.UnblockGameHudDeactivation();
		}
		else
		{
			MinigameComp.UnblockGameHudDeactivation();
			TeleportLoser();
		}

		System::SetTimer(this, n"RemoveBombPlayerCapabilitySheets", 0.75f, false);

		if (HorseManager.IsActorDisabled(this))
			HorseManager.EnableActor(this);

		HorseDerbyPlayerTrigger1.SetTriggerEnabled(true);
		HorseDerbyPlayerTrigger2.SetTriggerEnabled(true);

		OnBombRunCheckTheHellTower.Broadcast(true);
	}

	UFUNCTION()
	void RemoveBombPlayerCapabilitySheets()
	{
		MinigameComp.RemovePlayerCapabilitySheets();
	}

	UFUNCTION()
	void TeleportWinner()
	{
		FVector WorldTeleportLocMay = RootComponent.RelativeTransform.TransformPosition(EndGameLocs[0]);
		FVector WorldTeleportLocCody = RootComponent.RelativeTransform.TransformPosition(EndGameLocs[1]);
		
		if (Winner == Game::May)
			Game::GetMay().TeleportActor(WorldTeleportLocMay, ActorRotation);
		else
			Game::GetCody().TeleportActor(WorldTeleportLocCody, ActorRotation);
	}

	UFUNCTION()
	void TeleportLoser()
	{
		FVector WorldTeleportLocMay = RootComponent.RelativeTransform.TransformPosition(EndGameLocs[0]);
		FVector WorldTeleportLocCody = RootComponent.RelativeTransform.TransformPosition(EndGameLocs[1]);

		if (Loser == Game::May)
			Game::GetMay().TeleportActor(WorldTeleportLocMay, ActorRotation);
		else
			Game::GetCody().TeleportActor(WorldTeleportLocCody, ActorRotation);
	}

	UFUNCTION()
	void TeleportPlayer(AHazePlayerCharacter Player)
	{
		FVector WorldTeleportLoc = RootComponent.RelativeTransform.TransformPosition(EndGameLocs[Player]);
		Player.TeleportActor(WorldTeleportLoc, ActorRotation);
	}

	UFUNCTION(NetFunction)
	void ReachedLastRegenPoint(AHazePlayerCharacter Player)
	{
		if (PlayerCompCody == nullptr || PlayerCompMay == nullptr)
			return;

		if (!bGameActive)
			return;
			
		bGameActive = false;
		bGameTicking = false;

		GameWon(Player);
	}

	UFUNCTION()
	void GameWon(AHazePlayerCharacter Player)
	{
		if (Player == Game::Cody && CodyTime > 0.f)
		{
			PlayerCompMay.TimeBombWinLoseState = ETimeBombWinLoseState::Lose;
			PlayerCompMay.TimeBombState = ETimeBombState::Explosion;

		}
		else if (Player == Game::May && MayTime > 0.f)
		{
			PlayerCompCody.TimeBombWinLoseState = ETimeBombWinLoseState::Lose;
			PlayerCompCody.TimeBombState = ETimeBombState::Explosion;
		}
	}

	UFUNCTION(NetFunction)
	void EnableBombRegenPoint(ABombRegenPoint InputRegenPoint)
	{
		if (InputRegenPoint.IsActorDisabled())
			InputRegenPoint.EnableActor(this);
	}

	UFUNCTION(NetFunction)
	void DisableBombRegenPoint(ABombRegenPoint InputRegenPoint)
	{
		InputRegenPoint.DisableActor(this);
		InputRegenPoint.Disappear();
	}

	UFUNCTION()
	void VOInteractCheck(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		UInteractionComponent Interact;

		if (InteractComp == TimeBombDoubleInteract.LeftInteraction)
			Interact = TimeBombDoubleInteract.RightInteraction;
		else
			Interact = TimeBombDoubleInteract.LeftInteraction;

		MinigameComp.PlayPendingStartVOBark(Player, Interact.WorldLocation);
	}
}