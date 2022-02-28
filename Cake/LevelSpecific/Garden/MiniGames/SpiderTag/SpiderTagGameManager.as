import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagFloorManager;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagRespawnManager;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagStartingPoint;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagFloorDropOff;

enum ESpiderTagGameState
{
	Inactive,
	GameInPlay,
	AnnouncingWinner
}

enum ETagFollowCamState
{
	Inactive,
	FollowCody,
	FollowMay
};

class ASpiderTagGameManager : AHazeActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	//*** DISABLED FOR UXR ***//
	// default MinigameComp.bDisableTambourineCharacter = true; 
	
	UPROPERTY(Category =  "Setup")
	TPerPlayer<ATagStartingPoint> TagStartingPoints; 

	UPROPERTY(Category =  "Setup")
	AHazeCameraActor MainCamera;

	UPROPERTY(Category =  "Setup")
	AHazeCameraActor FollowCam;

	TPerPlayer<bool> bPlayerFollowCamActive;

	bool bSettingRotation;

	UPROPERTY(Category =  "Setup")
	ATagFloorManager TagFloorManager;

	UPROPERTY(Category = "Setup")
	ATagRespawnManager TagRespawnManager;

	UPROPERTY(Category = "Setup")
	ATagFloorDropOff TagFloorDropOff;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UCameraShakeBase> ExplosionCameraShake;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet CameraCapabilitySheet;

	// UPROPERTY(Category = "Capabilities")
	// TSubclassOf<UHazeCapability> BlockCapability;

	TPerPlayer<AHazePlayerCharacter> PlayerReferences;

	TPerPlayer<USpiderTagPlayerComp> PlayerComps;
	
	ESpiderTagGameState SpiderTagGameState;

	ETagFollowCamState TagFollowCamState;

	int Players;
	int MaxPlayers = 2;
	
	bool bCanSetGameStartTimer;

	float MaxGameTime = 15.f;
	float CurrentGameTime;

	float GameStartDelay = 0.8f;
	float CurrentGameStartTimer;

	float LoseFloorTime;
	float LoseFloorDefaultTime = 3.5f;

	float NetTime;
	float NetRate = 0.4f;

	bool bCanShake;
	float ShakeTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TagStartingPoints[0].InteractionComp.OnActivated.AddUFunction(this, n"AddPlayer");
		TagStartingPoints[1].InteractionComp.OnActivated.AddUFunction(this, n"AddPlayer");

		TagStartingPoints[0].OnPlayerCancelledEvent.AddUFunction(this, n"RemovePlayer");
		TagStartingPoints[1].OnPlayerCancelledEvent.AddUFunction(this, n"RemovePlayer");

		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"StartGame");
		MinigameComp.OnMinigamePlayerLeftEvent.AddUFunction(this, n"PlayerLeftMidGame");

		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"EndGame");

		PlayerReferences[0] = Game::GetMay();
		PlayerReferences[1] = Game::GetCody();

		TagRespawnManager.OnRespawnActivatedEvent.AddUFunction(this, n"NetSetPlayerAsIt");

		AddCapabilitySheet(CameraCapabilitySheet);

		System::SetTimer(this, n"Shake", 1.2f, false);

	}

	UFUNCTION()
	void Shake()
	{
		PlayerReferences[0].PlayCameraShake(ExplosionCameraShake);
		PlayerReferences[1].PlayCameraShake(ExplosionCameraShake);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanShake)
		{
			PlayerReferences[0].PlayCameraShake(ExplosionCameraShake);
			PlayerReferences[1].PlayCameraShake(ExplosionCameraShake);

			ShakeTime -= DeltaTime;

			if (ShakeTime <= 0.f)
				bCanShake = false;
		}

		if (bCanSetGameStartTimer)
		{
			CurrentGameStartTimer -= DeltaTime;

			if (CurrentGameStartTimer <= 0.f)
			{
				bCanSetGameStartTimer = false;
				InitiateCountDown();
			}
		}

		if (SpiderTagGameState == ESpiderTagGameState::GameInPlay)
		{
			if (HasControl())
				UpdatingScore();
		}
	}

	void InitiateCountDown()
	{
		MinigameComp.AddPlayerCapabilitySheets();

		PlayerComps[0] = USpiderTagPlayerComp::Get(PlayerReferences[0]);
		PlayerComps[1] = USpiderTagPlayerComp::Get(PlayerReferences[1]);

		PlayerComps[0].TimeAsIt = PlayerComps[0].MaxItTime;
		PlayerComps[1].TimeAsIt = PlayerComps[1].MaxItTime;

		PlayerComps[0].OtherPlayersComp = PlayerComps[1];
		PlayerComps[1].OtherPlayersComp = PlayerComps[0];

		PlayerComps[0].MainCamera = MainCamera;
		PlayerComps[1].MainCamera = MainCamera;

		PlayerComps[0].SpiderTagPlayerState = ESpiderTagPlayerState::MovementBlocked;
		PlayerComps[1].SpiderTagPlayerState = ESpiderTagPlayerState::MovementBlocked;

		PlayerComps[0].OnTagPlayerAnnounceWinnerEvent.AddUFunction(this, n"AnnounceWinner");
		PlayerComps[1].OnTagPlayerAnnounceWinnerEvent.AddUFunction(this, n"AnnounceWinner");

		PlayerComps[0].OnTagPlayerExplodedEvent.AddUFunction(this, n"LoserActivationEvent");
		PlayerComps[1].OnTagPlayerExplodedEvent.AddUFunction(this, n"LoserActivationEvent");

		MinigameComp.StartCountDown();

		UTagCancelComp CancelComp1 = UTagCancelComp::Get(PlayerReferences[0]);
		UTagCancelComp CancelComp2= UTagCancelComp::Get(PlayerReferences[1]);
		
		if (CancelComp1 != nullptr)
			CancelComp1.bCanCancel = false;
		
		if (CancelComp2 != nullptr)
			CancelComp2.bCanCancel = false;

		if (HasControl())
		{
			TagFloorManager.SetFloorsGameActiveState(true);
			NetGameCameraOn();
		}
	
		if (HasControl())
			System::SetTimer(this, n"DelayedTeleportPlayer", 1.2f, false);
	}

	UFUNCTION(NetFunction)
	void NetGameCameraOn()
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		
		MainCamera.ActivateCamera(Game::May, Blend, this); 
		MainCamera.ActivateCamera(Game::Cody, Blend, this); 

		Game::May.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		Game::Cody.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
	}

	UFUNCTION(NetFunction)
	void NetGameCameraOff()
	{
		MainCamera.DeactivateCamera(Game::May, 0.2f);
		MainCamera.DeactivateCamera(Game::Cody, 0.2f);
	}

	UFUNCTION(NetFunction)
	void DelayedTeleportPlayer()
	{
		TagStartingPoints[0].TeleportInteractingPlayer();
		TagStartingPoints[1].TeleportInteractingPlayer();
		TagFloorDropOff.TagFloorDropOffState = ETagFloorDropOffState::DropDown;
	}

	UFUNCTION()
	void StartGame()
	{
		CurrentGameTime = MaxGameTime;
		
		SpiderTagGameState = ESpiderTagGameState::GameInPlay;

		PlayerComps[0].SpiderTagPlayerState = ESpiderTagPlayerState::InPlay;
		PlayerComps[1].SpiderTagPlayerState = ESpiderTagPlayerState::InPlay;

		int R = FMath::RandRange(0, 1);

		if (HasControl())
			NetSetPlayerAsIt(PlayerReferences[0]);
	
		TagRespawnManager.bIsActive = true;

		MinigameComp.bDontSpawnTambourineCharacter = true;

		TagStartingPoints[0].RemoveStartPointCapabilities();
		TagStartingPoints[1].RemoveStartPointCapabilities();
	}

	UFUNCTION(NetFunction)
	void NetSetPlayerAsIt(AHazePlayerCharacter Player)
	{
		if (Player == PlayerReferences[0])
		{
			PlayerComps[0].bWeAreIt = true; 
			PlayerComps[1].bWeAreIt = false; 
		}
		else 
		{
			PlayerComps[0].bWeAreIt = false; 
			PlayerComps[1].bWeAreIt = true;		
		}
	}

	UFUNCTION(NetFunction)
	void LoserActivationEvent(AHazePlayerCharacter Player)
	{
		if (HasControl())
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 1.2f;
			NetGameCameraOff();
			
			FollowCam.ActivateCamera(Game::May, Blend, this); 
			FollowCam.ActivateCamera(Game::Cody, Blend, this); 
		}

		PlayerComps[0].bMovementBlocked = true;
		PlayerComps[1].bMovementBlocked = true;

		Game::May.BlockCapabilities(n"Respawn", this);
		Game::Cody.BlockCapabilities(n"Respawn", this);

		if (Player == Game::May)
		{
			TagFollowCamState = ETagFollowCamState::FollowMay;
			bPlayerFollowCamActive[0] = true;
			bPlayerFollowCamActive[1] = false;
		}
		else
		{
			TagFollowCamState = ETagFollowCamState::FollowCody;
			bPlayerFollowCamActive[0] = false;
			bPlayerFollowCamActive[1] = true;
		}
	}

	UFUNCTION()
	void AnnounceWinner(AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;

		if (Player == Game::May)
			NetAnnounceWinner(Game::Cody);
		else 
			NetAnnounceWinner(Game::May);

		ShakeTime = 0.8f;
		bCanShake = true;
		
		SpiderTagGameState = ESpiderTagGameState::AnnouncingWinner;
	}

	UFUNCTION(NetFunction)
	void NetAnnounceWinner(AHazePlayerCharacter Player)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.f;
		
		if (Player == Game::May)
		{
			TagFollowCamState = ETagFollowCamState::FollowMay;
			bPlayerFollowCamActive[0] = true;
			bPlayerFollowCamActive[1] = false;
		}
		else
		{
			TagFollowCamState = ETagFollowCamState::FollowCody;
			bPlayerFollowCamActive[0] = false;
			bPlayerFollowCamActive[1] = true;
		}

		SpiderTagGameState = ESpiderTagGameState::AnnouncingWinner;

		MinigameComp.AnnounceWinner(Player);

		TagFloorDropOff.TagFloorDropOffState = ETagFloorDropOffState::RiseUp;

		Game::May.UnblockCapabilities(n"Respawn", this);
		Game::Cody.UnblockCapabilities(n"Respawn", this);
		

	}

	UFUNCTION()
	void PlayerLeftMidGame(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
			MinigameComp.AnnounceWinner(Game::Cody);
		else
			MinigameComp.AnnounceWinner(Game::May);
		
		MinigameComp.RemovePlayerCapabilitySheets();
	}
	
	UFUNCTION()
	void EndGame()
	{
		System::SetTimer(this, n"DelayedEndGame", 1.f, false);
	}

	UFUNCTION()
	void DelayedEndGame()
	{
		if(HasControl())
			NetEndGame();
	}

	UFUNCTION(NetFunction)
	void NetEndGame()
	{
		TagFollowCamState = ETagFollowCamState::Inactive;

		SpiderTagGameState = ESpiderTagGameState::Inactive;

		SpiderTagGameState = ESpiderTagGameState::Inactive;
		
		TagFloorManager.ResetFloors();

		PlayerComps[0].bMovementBlocked = false;
		PlayerComps[1].bMovementBlocked = false;

		// MinigameComp.EndGameHud();
		MinigameComp.RemovePlayerCapabilitySheets();

		TagRespawnManager.bIsActive = false;

		TagStartingPoints[0].InteractionComp.Enable(n"TagMinigame Interaction");
		TagStartingPoints[1].InteractionComp.Enable(n"TagMinigame Interaction");


		if (HasControl())
		{
			TagFloorManager.SetFloorsGameActiveState(false);
			FollowCam.DeactivateCamera(Game::May, 1.2f); 
			FollowCam.DeactivateCamera(Game::Cody, 1.2f); 			
		}
		
		Players = 0;

		if (bPlayerFollowCamActive[0])
		{
			bPlayerFollowCamActive[0] = false;

			Game::Cody.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Normal);
			Game::May.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Normal);
		}

		if (bPlayerFollowCamActive[1])
		{
			bPlayerFollowCamActive[1] = false;
					
			Game::May.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Normal);
			Game::Cody.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Normal);
		}

		bSettingRotation = true;
	}

	void UpdatingScore()
	{
		if (!HasControl())
			return;
		
		MinigameComp.SetScore(PlayerReferences[0], PlayerComps[0].TimeAsIt); 
		MinigameComp.SetScore(PlayerReferences[1], PlayerComps[1].TimeAsIt); 

		if (NetTime <= System::GameTimeInSeconds)
		{
			NetTime = System::GameTimeInSeconds + NetRate;
			NetUpdatingScore(PlayerComps[0].TimeAsIt, PlayerComps[1].TimeAsIt);
		}
	}

	UFUNCTION(NetFunction)
	void NetUpdatingScore(float TimeAsitComp1, float TimeAsitComp2)
	{
		if (!HasControl())
		{
			MinigameComp.SetScore(PlayerReferences[0], TimeAsitComp1); 
			MinigameComp.SetScore(PlayerReferences[1], TimeAsitComp2); 
		}
	}

	UFUNCTION()
	void AddPlayer(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Players++;
		
		InteractComp.Disable(n"TagMinigame Interaction");

		if (Players == MaxPlayers)
		{
			if (SpiderTagGameState == ESpiderTagGameState::Inactive)
			{
				CurrentGameStartTimer = GameStartDelay;
				bCanSetGameStartTimer = true;
			}
		}
	}

	UFUNCTION()
	void RemovePlayer(UInteractionComponent InteractComp, AHazePlayerCharacter Player,  ATagStartingPoint TagStartingPoint)
	{
		Players--;
		bCanSetGameStartTimer = false;

		InteractComp.Enable(n"TagMinigame Interaction");

		TagStartingPoint.RemoveStartPointCapabilities();

	}
}