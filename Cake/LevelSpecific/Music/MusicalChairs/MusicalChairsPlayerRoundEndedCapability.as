import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

class UMusicalChairsPlayerRoundEndedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	AMusicalChairsActor MusicalChairs;
	UMusicalChairsPlayerComponent MusicalChairsComp;
	
	ACymbal Cymbal;

	FTransform TransformBefore;

	FTimerHandle PlayGenericFailTimer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		MusicalChairsComp = UMusicalChairsPlayerComponent::Get(Owner);
		MusicalChairs = MusicalChairsComp.MusicalChairs;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MusicalChairs.bRoundEnded)
			return EHazeNetworkActivation::DontActivate;
		if(MusicalChairs.bGameOver)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MusicalChairs.bRoundEnded)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if(MusicalChairs.bGameOver)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bool bPlayWinningCamera = false;

		if(Player.IsMay())
		{
			if(MusicalChairs.WinState == EMusicalChairsRoundWinState::MayWon)
			{
				//MusicalChairs.AddScoreToMay();
				PlayerWon();

				bPlayWinningCamera = true;
			}
			else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::MayLost)
			{
				PlayerLost(true);
			}
			else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::CodyWon)
			{
				PlayerLost(false);

				bPlayWinningCamera = true;
			}
			else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::CodyLost)
			{
				//MusicalChairs.AddScoreToMay();
			}
		}
		else
		{
			if(MusicalChairs.WinState == EMusicalChairsRoundWinState::CodyWon)
			{
				//MusicalChairs.AddScoreToCody();
				PlayerWon();

				bPlayWinningCamera = true;
			}
			else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::CodyLost)
			{
				PlayerLost(true);
			}
			else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::MayWon)
			{
				PlayerLost(false);

				bPlayWinningCamera = true;
			}
			else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::MayLost)
			{
				//MusicalChairs.AddScoreToCody();
			}
		}

		//ActivateJumpTo(MusicalChairs.SitLocation.GetWorldTransform(), n"SeatReached");

		if(bPlayWinningCamera)
		{
			FHazeCameraBlendSettings BlendSettings;
			Player.ActivateCamera(MusicalChairs.WinningCamera, BlendSettings, this, EHazeCameraPriority::Maximum);
		}
		else
		{
			if(MusicalChairs.WinState == EMusicalChairsRoundWinState::MayLost)
				MusicalChairs.LosingCameraRoot.SetWorldLocation(Game::GetCody().ActorLocation);
			else
				MusicalChairs.LosingCameraRoot.SetWorldLocation(Game::GetMay().ActorLocation);

			FHazeCameraBlendSettings BlendSettings;
			Player.ActivateCamera(MusicalChairs.LosingCamera, BlendSettings, this, EHazeCameraPriority::Maximum);
		}

		TransformBefore = Player.GetActorTransform();
	}


	UFUNCTION()
	void PlayerLost(bool PlayerFailed)
	{
		Niagara::SpawnSystemAtLocation(MusicalChairs.LoserEffect, Player.ActorLocation);
		Player.SetActorHiddenInGame(true);

		if(Player.IsMay())
				Player.PlayerHazeAkComp.HazePostEvent(MusicalChairs.MayDeathEvent);
			else
				Player.PlayerHazeAkComp.HazePostEvent(MusicalChairs.CodyDeathEvent);

		MusicalChairsComp.bExploded = true;

		Player.PlayForceFeedback(MusicalChairs.LoserRumble, false, true, n"MusicalChairsFail");


		if(Cymbal == nullptr && Player.IsCody())
		{
				if(UCymbalComponent::Get(Player) != nullptr)
				{
					if(UCymbalComponent::Get(Player).GetCymbalActor() != nullptr)
					{
						Cymbal = UCymbalComponent::Get(Player).GetCymbalActor();
					}
				}
			
		}

		if(Cymbal != nullptr && Player.IsCody())
			Cymbal.SetActorHiddenInGame(true);


		if(PlayerFailed)
			MusicalChairsComp.bFailedRound = true;

		if(PlayerFailed)
		{
			int OtherPlayerScore = Player.IsMay() ? MusicalChairs.GameScoreData.CodyScore : MusicalChairs.GameScoreData.MayScore;

			if(OtherPlayerScore < MusicalChairs.ScoreLimit)
				PlayGenericFailTimer = System::SetTimer(this, n"PlayFailGenericVOBark", 1.8f, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayFailGenericVOBark()
	{
		MusicalChairs.MinigameComp.PlayFailGenericVOBark(Player);
	}

	UFUNCTION()
	void PlayerWon()
	{
		MusicalChairsComp.bWonRound = true;

		//Player.UnblockCapabilities(CapabilityTags::Movement, MusicalChairs);
		//Player.UnblockCapabilities(CapabilityTags::Collision, MusicalChairs);

		//Player.BlockCapabilities(CapabilityTags::MovementInput, MusicalChairs);

		ActivateJumpTo(MusicalChairs.SitLocation.GetWorldTransform(), n"SeatReached");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		System::ClearAndInvalidateTimerHandle(PlayGenericFailTimer);

		if(!MusicalChairs.bGameOver)
		{
			if(MusicalChairsComp.bWonRound)
			{
				ResetWinningPlayer();
			}
			else
			{
				Player.DeactivateCameraByInstigator(this);
			}
		}
		else
		{
			if(MusicalChairsComp.bWonRound)
				Player.StopAllSlotAnimations();

			if(Player.CurrentlyUsedCamera == MusicalChairs.LosingCamera)
			{
				Player.DeactivateCamera(MusicalChairs.LosingCamera);
			}
		}

		if(Player.GetbHidden())
		{
			Player.SetActorHiddenInGame(false);
			MusicalChairsComp.bExploded = false;

			UNiagaraSystem RespawnEffect = Player.IsMay() ? MusicalChairs.MayRespawnEffect : MusicalChairs.CodyRespawnEffect;

			if(Player.IsMay())
				Player.PlayerHazeAkComp.HazePostEvent(MusicalChairs.MayRespawnEvent);
			else
				Player.PlayerHazeAkComp.HazePostEvent(MusicalChairs.CodyRespawnEvent);

			Niagara::SpawnSystemAtLocation(RespawnEffect, Player.ActorLocation, Player.ActorRotation);

			MusicalChairsComp.bRequestLocomotion = true;
		}

		if(Cymbal != nullptr && Player.IsCody())
		{
			if(Cymbal.GetbHidden())
				Cymbal.SetActorHiddenInGame(false);
		}

		if(MusicalChairsComp.bWonRound)
			MusicalChairsComp.bWonRound = false;

		if(MusicalChairsComp.bFailedRound)
			MusicalChairsComp.bFailedRound = false;
	}

	UFUNCTION()
	void ResetWinningPlayer()
	{
		ActivateJumpTo(TransformBefore/*AttachComp.GetWorldTransform()*/, n"ReturnLocationReached");

		Player.DeactivateCameraByInstigator(this);

		Player.StopAllSlotAnimations();
	}

	UFUNCTION()
	void ActivateJumpTo(FTransform DestinationTransform, FName CallbackFunction)
	{
		FHazeDestinationEvents DestinationEvents;
		DestinationEvents.OnDestinationReached.BindUFunction(this, CallbackFunction);

		FHazeJumpToData JumpData;
		JumpData.Transform = DestinationTransform;
		JumpTo::ActivateJumpTo(Player, JumpData, DestinationEvents);
	}

	UFUNCTION()
	void SeatReached(AHazeActor Actor)
	{
		UAnimSequence WinLandingAnim = Player.IsMay() ? MusicalChairs.MayWinLanding : MusicalChairs.CodyWinLanding;

		Player.PlayForceFeedback(MusicalChairs.LandOnChairRumble, false, true, n"MusicalChairsSeatReached");

		Player.PlaySlotAnimation(Animation = WinLandingAnim, bLoop = false, BlendTime = 0.03f);
		MusicalChairs.PlayerOnChair = Player;

		MusicalChairs.MinigameComp.PlayTauntAllVOBark(Player);
	}

	UFUNCTION()
	void ReturnLocationReached(AHazeActor Actor)
	{
		UAnimSequence ResetLandingAnim = Player.IsMay() ? MusicalChairs.MayResetLanding : MusicalChairs.CodyResetLanding;

		Player.PlayForceFeedback(MusicalChairs.LandOnChairRumble, false, true, n"MusicalChairsReturnLocationReached");
		Player.PlaySlotAnimation(Animation = ResetLandingAnim, bLoop = false, BlendTime = 0.03f);

		MusicalChairs.PlayerOnChair = nullptr;
		MusicalChairsComp.bRequestLocomotion = true;
	}

}

