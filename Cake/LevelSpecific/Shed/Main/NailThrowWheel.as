import Vino.Interactions.InteractionComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.MovementSettings;
import Vino.Movement.MovementSystemTags;
import Vino.MinigameScore.ScoreHud;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Shed.Main.Audio.WheelMiniGameAudioComponent;
import Cake.LevelSpecific.Shed.Main.WheelHatch;
import Vino.MinigameScore.MinigameComp;

class ANailThrowWheel : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TSubclassOf<UScoreHud> ScoreHudClass;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent WheelMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CodyPlatform;

	UPROPERTY(DefaultComponent, Attach = WheelMesh)
	UStaticMeshComponent Rink;

	UPROPERTY(DefaultComponent, Attach = WheelMesh)
	UStaticMeshComponent CogWheel;

	UPROPERTY(DefaultComponent)
	UWheelMiniGameAudioComponent WheelMiniGameAudioComp;

	UPROPERTY()
	AHazeCameraActor MayCam;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY()
	UAnimSequence WinningAnimation;

	UPROPERTY()
	UAnimSequence LosingAnimation;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::NailThrow;

	EMinigameWinner GameWinner;
	
	bool SpinTheWheel = false;

	bool WheelActive = false;

	float DefaultRotationSpeed = 20.f;

	float WheelRotationSpeedMultiplier = 1.f;

	float TargetWheelRotationSpeedMultiplier = 1.f;

	int MayFinalNetworkScore;

	int CodyFinalNetworkScore;

	bool CodyScoreReceived;

	bool MayScoreReceived;

	int AmountOfTimesFunctionRun = 0;

	bool GameOver = false;

	float RemoteSideError = 0.f;
	float ControlSideSyncTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"StartWheelMinigame");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"CancelFromTutorial");
		MinigameComp.OnEndMinigameReactionsComplete.AddUFunction(this, n"HatchResetAfterAnimations");
		MinigameComp.OnMayReactionComplete.AddUFunction(this, n"MayReactionAnimComplete");
		MinigameComp.OnCodyReactionComplete.AddUFunction(this, n"CodyReactionAnimComplete");
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountdownFinished");
		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"OnWinnerScreenFinished");
	}

	UFUNCTION()
	void BothPlayersAreReady()
	{
		ActivateMayWheel();
		ActivateCodyWheel();
		System::SetTimer(this, n"StartTutorial", 2.f, bLooping=false);
	}

	UFUNCTION()
	void StartTutorial()
	{
		MinigameComp.ActivateTutorial();
	}

	UFUNCTION()
	void StartWheelMiniGame()
	{
		MinigameComp.StartCountDown();
		Game::GetCody().UnblockCapabilities(n"StickInput", this);
	}

	UFUNCTION()
	void ActivateMayWheel()
	{
		Game::GetMay().TriggerMovementTransition(this);
		
		//May Camera
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		MayCam.ActivateCamera(Game::GetMay(), Blend, this, EHazeCameraPriority::Script);

		
		//Block may movement
		Game::GetMay().BlockCapabilities(CapabilityTags::MovementInput, this);
		Game::GetMay().BlockCapabilities(MovementSystemTags::Jump, this);
	}


	UFUNCTION()
	void ActivateCodyWheel()
	{
		// Game::GetCody().TeleportActor(CodyPlatform.GetWorldLocation(), CodyPlatform.GetWorldRotation());
		
		Game::GetCody().TriggerMovementTransition(this);
		
		//Cody MoveTo on platform
		FHazeMoveToDestinationSettings MoveToSettings;
		FHazeDestinationEvents MoveToEvents;
		MoveToSettings.bCanCancel = false;
		MoveToSettings.ControllerType = EHazeDestinationControlType::Local;

		Game::GetCody().MoveTo(CodyPlatform.GetWorldLocation(), CodyPlatform.GetWorldRotation(), MoveToSettings, MoveToEvents);
				
		Game::GetCody().BlockCapabilities(CapabilityTags::MovementInput, this);
		Game::GetCody().BlockCapabilities(n"Crouch", this);
		
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		Game::GetCody().ApplyCameraSettings(CamSettings, Blend, this, EHazeCameraPriority::Script);

		Game::GetCody().SetCapabilityActionState(n"AlwaysAim", EHazeActionState::Active);

		Game::GetCody().BlockCapabilities(n"NailThrow", this);
		Game::GetCody().BlockCapabilities(n"StickInput", this);

		FHazePointOfInterest POIBoy;
		POIBoy.Duration = 3.f;
		POIBoy.Blend = 3.f;
		POIBoy.FocusTarget.Actor = this;
		Game::GetCody().ApplyForcedClampedPointOfInterest(POIBoy, this, EHazeCameraPriority::Maximum);
	}



	UFUNCTION()
	void CountdownFinished()
	{
		Game::GetMay().UnblockCapabilities(CapabilityTags::MovementInput, this);
		Game::GetCody().UnblockCapabilities(n"NailThrow", this);
		WheelActive = true;
		
		BP_ReadyTheHatches();

		WheelMiniGameAudioComp.StartMachineAudio();
		WheelMiniGameAudioComp.PlayAllHatchesFlipUp();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Wheel rotation
		WheelRotationSpeedMultiplier = FMath::FInterpTo(WheelRotationSpeedMultiplier, TargetWheelRotationSpeedMultiplier, DeltaTime, 10.f);
		TargetWheelRotationSpeedMultiplier -= 1.f * DeltaTime;
		TargetWheelRotationSpeedMultiplier = FMath::Clamp(TargetWheelRotationSpeedMultiplier, 1.f, 2.f);

		float NewRotationSpeed = DefaultRotationSpeed * WheelRotationSpeedMultiplier;

		if (WheelActive)
		{
			WheelMesh.AddLocalRotation(FRotator(0.f, NewRotationSpeed * DeltaTime, 0.f));

			if (Network::IsNetworked())
			{
				if (!HasControl())
				{
					// On the remote side, we want to shave off the error we might have built up
					// so that the rotation is hella synced
					float ErrorDelta = RemoteSideError * 0.8f * DeltaTime;
					RemoteSideError -= ErrorDelta;
					WheelMesh.AddLocalRotation(FRotator(0.f, ErrorDelta, 0.f));
				}
				else
				{
					// On the control side, we want to periodically send over our rotation so that the remote side can
					// sync up 
					float CurrentTime = Time::GameTimeSeconds;
					if (CurrentTime > ControlSideSyncTime)
					{
						NetUpdateRemoteSideError(WheelMesh.RelativeRotation.Yaw);
						ControlSideSyncTime = CurrentTime + 5.f;
					}
				}
			}
		}
	}


	UFUNCTION()
	void AddCodyScore(float ScoreToAdd, FVector Location)
	{
		if (!GameOver)
		{
			MinigameComp.AdjustScore(Game::GetCody(), ScoreToAdd, false);
			FMinigameWorldWidgetSettings Settings;
			Settings.MinigameTextColor = EMinigameTextColor::Cody;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "+1", Location, Settings);
			MinigameComp.PlayTauntAllVOBark(Game::GetCody());

			WheelMiniGameAudioComp.PlayHatchHit(Game::GetCody());

			//Check if player won
			if (MinigameComp.ScoreData.CodyScore >= MinigameComp.ScoreData.ScoreLimit)
			{
				if (Network::IsNetworked())
				{
					if(Game::Cody.HasControl())
					{
						NetGameOver();
					}
				}
				else
				{
					GameWinner = EMinigameWinner::Cody;
					WinnerHasBeenDecided(GameWinner);
				}
			}
		}
	}

	UFUNCTION()
	void AddMayScore(float ScoreToAdd, FVector Location)
	{
		if (!GameOver)
		{
			MinigameComp.AdjustScore(Game::GetMay(), ScoreToAdd, false);
			FMinigameWorldWidgetSettings Settings;
			Settings.MinigameTextColor = EMinigameTextColor::May;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "+1", Location, Settings);
			MinigameComp.PlayTauntAllVOBark(Game::GetMay());

			WheelMiniGameAudioComp.PlayHatchHit(Game::GetMay());
			
			if (MinigameComp.ScoreData.MayScore < MinigameComp.ScoreData.CodyScore)
			{
				TargetWheelRotationSpeedMultiplier = 20.f;
				WheelMiniGameAudioComp.PlayMachineSpeedup();
			}

			//Check if player won
			if (MinigameComp.ScoreData.MayScore >= MinigameComp.ScoreData.ScoreLimit)
			{
				if (Network::IsNetworked())
				{
					if(Game::GetMay().HasControl())
					{
						NetGameOver();
					}
				}
				else
				{
					GameWinner = EMinigameWinner::May;
					WinnerHasBeenDecided(GameWinner);
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetGameOver()
	{
		if (GameOver)
		{
			return;
		}
		
		GameOver = true;

		if (Game::GetCody().HasControl())
			NetDecideWinner(Game::Cody, MinigameComp.ScoreData.CodyScore);

		if (Game::GetMay().HasControl())
			NetDecideWinner(Game::May, MinigameComp.ScoreData.MayScore);
	}

	UFUNCTION(NetFunction)
	void NetDecideWinner(AHazePlayerCharacter Player, int Score)
	{

		if (Player == Game::GetMay())
		{
			MayFinalNetworkScore = Score;
			MayScoreReceived = true;
		}
		
		if (Player == Game::GetCody())
		{
			CodyFinalNetworkScore = Score;
			CodyScoreReceived = true;
		}

		if (MayScoreReceived && CodyScoreReceived)
		{
			MinigameComp.ScoreData.MayScore = MayFinalNetworkScore;
			MinigameComp.ScoreData.CodyScore = CodyFinalNetworkScore;

			MinigameComp.SetScore(Game::GetCody(), MinigameComp.ScoreData.CodyScore);
			MinigameComp.SetScore(Game::GetMay(), MinigameComp.ScoreData.MayScore);

			if (CodyFinalNetworkScore == MayFinalNetworkScore)
			{
				GameWinner = EMinigameWinner::Draw;
				WinnerHasBeenDecided(GameWinner);
				return;
			}

			if (CodyFinalNetworkScore > MayFinalNetworkScore)
				GameWinner = EMinigameWinner::Cody;
			else
				GameWinner = EMinigameWinner::May;

			WinnerHasBeenDecided(GameWinner);
		}
		
	}

	UFUNCTION()
	void WinnerHasBeenDecided(EMinigameWinner MiniGameWinner)
	{
		AHazePlayerCharacter WinningPlayer = nullptr;
		AHazePlayerCharacter LosingPlayer = nullptr;

		GameOver = true;

		switch(MiniGameWinner)
		{
			case EMinigameWinner::Cody:
				WinningPlayer = Game::GetCody();
				LosingPlayer = WinningPlayer.OtherPlayer;
				break;

			case EMinigameWinner::Draw:
				break;

			case EMinigameWinner::May:
				WinningPlayer = Game::GetMay();
				LosingPlayer = WinningPlayer.OtherPlayer;
				break;
		}

		WheelActive = false;
		
		MinigameComp.AnnounceWinner(MiniGameWinner);
	
		Game::GetCody().BlockCapabilities(n"NailThrow", this);

		AmountOfTimesFunctionRun = 0;
		CodyFinalNetworkScore = 0.f;
		MayFinalNetworkScore = 0.f;
		MayScoreReceived = false;
		CodyScoreReceived = false;

		// BP_ResetTheHatches();

		WheelMiniGameAudioComp.MinigameFinished();
	}

	UFUNCTION()
	void HatchResetAfterAnimations()
	{
 		BP_ResetTheHatches();
		WheelMiniGameAudioComp.PlayAllHatchesFlipUp();
	}

	//NOTE:
	// Hook up to individual events instead for finishing animations - unblock when appropriate - will need separate functions instead of the OnWinnerScreenFinished

	UFUNCTION()
	void MayReactionAnimComplete()
	{
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Jump, this);
		Game::GetMay().DeactivateCameraByInstigator(this);
	}

	UFUNCTION()
	void CodyReactionAnimComplete()
	{
		Game::GetCody().UnblockCapabilities(CapabilityTags::MovementInput, this);
		Game::GetCody().ClearCameraSettingsByInstigator(this);
		Game::GetCody().SetCapabilityActionState(n"AlwaysAim", EHazeActionState::Inactive);
		Game::GetCody().UnblockCapabilities(n"NailThrow", this);
		Game::GetCody().UnblockCapabilities(n"Crouch", this);
	}

	UFUNCTION()
	void OnWinnerScreenFinished()
	{
		MinigameComp.ResetScoreBoth();
		GameOver = false;
	}

	UFUNCTION()
	void CancelFromTutorial()
	{
		Game::GetMay().UnblockCapabilities(CapabilityTags::MovementInput, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Jump, this);
		Game::GetMay().DeactivateCameraByInstigator(this);
		Game::GetCody().UnblockCapabilities(CapabilityTags::MovementInput, this);
		Game::GetCody().ClearCameraSettingsByInstigator(this);
		Game::GetCody().SetCapabilityActionState(n"AlwaysAim", EHazeActionState::Inactive);
		Game::GetCody().UnblockCapabilities(n"NailThrow", this);
		Game::GetCody().UnblockCapabilities(n"Crouch", this);
		Game::GetCody().UnblockCapabilities(n"StickInput", this);
		BP_ResetTheHatches();
	}

	UFUNCTION(NetFunction)
	void NetUpdateRemoteSideError(float ControlSideRotation)
	{
		if (HasControl())
			return;

		float LocalRotation = WheelMesh.RelativeRotation.Yaw;
		RemoteSideError = FMath::FindDeltaAngleDegrees(LocalRotation, ControlSideRotation);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ResetTheHatches()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_ReadyTheHatches()
	{
		
	}
}