import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsPlayerScoreCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	AMusicalChairsActor MusicalChairs;
	UMusicalChairsPlayerComponent MusicalChairsComp;

	bool bIsWinningPlayer = false;

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
		if(!MusicalChairs.bGameOver)
			return EHazeNetworkActivation::DontActivate;
		if(!MusicalChairs.bMiniGameIsOn)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MusicalChairs.bMiniGameIsOn)
			return EHazeNetworkDeactivation::DeactivateLocal;	
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(Player.CurrentlyUsedCamera != MusicalChairs.WinningCamera && MusicalChairs.MinigameComp.GetCodyScore() != MusicalChairs.MinigameComp.GetMayScore())
		{
			FHazeCameraBlendSettings BlendSettings;
			Player.ActivateCamera(MusicalChairs.WinningCamera, BlendSettings, MusicalChairs, EHazeCameraPriority::Maximum);
		}

		bool bWon = false;

		if(MusicalChairsComp.bRequestLocomotion)
			MusicalChairsComp.bRequestLocomotion = false;

		if(Player.IsCody())
		{
			if(MusicalChairs.MinigameComp.GetCodyScore() > MusicalChairs.MinigameComp.GetMayScore())
				bWon = true;
		}
		else
		{
			if(MusicalChairs.MinigameComp.GetMayScore() > MusicalChairs.MinigameComp.GetCodyScore())
				bWon = true;
		}

		if(bWon)
		{
			PlayerWon();
		}
		else
		{
			//Player.UnblockCapabilities(CapabilityTags::Movement, MusicalChairs);
			 //Player.UnblockCapabilities(CapabilityTags::Collision, MusicalChairs);
			//Player.BlockCapabilities(CapabilityTags::MovementInput, MusicalChairs);
		}
	}

	UFUNCTION()
	void PlayerWon()
	{
		bIsWinningPlayer = true;

		if(Player != MusicalChairs.PlayerOnChair)
		{
			//Player.UnblockCapabilities(CapabilityTags::Movement, MusicalChairs);
			//Player.UnblockCapabilities(CapabilityTags::Collision, MusicalChairs);
			//Player.BlockCapabilities(CapabilityTags::MovementInput, MusicalChairs);

			ActivateJumpTo(MusicalChairs.SitLocation.GetWorldTransform(), n"SeatReached");
		}
		else
		{
			SeatReached(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bIsWinningPlayer)
			ResetWinningPlayer();
		else
		{
			//Player.UnblockCapabilities(CapabilityTags::Movement, MusicalChairs);
			//Player.UnblockCapabilities(CapabilityTags::Collision, MusicalChairs);
			Player.UnblockCapabilities(CapabilityTags::MovementInput, MusicalChairs);
		}

		Player.UnblockCapabilities(n"CameraControl", MusicalChairs);
		Player.UnblockCapabilities(n"LevelSpecific", MusicalChairs);
		Player.UnblockCapabilities(MovementSystemTags::Swinging, MusicalChairs);

		Player.DeactivateCamera(MusicalChairs.WinningCamera);
	}

	UFUNCTION()
	void ResetWinningPlayer()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, MusicalChairs);
		bIsWinningPlayer = false;
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
		MusicalChairs.WinnerReachedSeat();
		Player.PlayForceFeedback(MusicalChairs.LandOnChairRumble, false, true, n"MusicalChairsSeatReached");

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	
	}
}

