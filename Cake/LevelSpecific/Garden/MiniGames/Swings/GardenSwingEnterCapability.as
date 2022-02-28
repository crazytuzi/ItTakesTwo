import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent;
import Vino.Movement.Components.MovementComponent;

class UGardenSwingEnterCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GardenSwings");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UGardenSwingPlayerComponent SwingComp;
	AGardenSwingsActor Swings;

	UGardenSingleSwingComponent PlayerSwing;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingComp = UGardenSwingPlayerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);

		Swings = SwingComp.Swings;
		PlayerSwing = SwingComp.CurrentSwing;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlayerSwing.CurrentPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(PlayerSwing.bSwinging)
			return EHazeNetworkActivation::DontActivate;
		if(SwingComp.bInAir)
			return EHazeNetworkActivation::DontActivate;
		if(SwingComp.bAwaitingScore)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlayerSwing.bCancelledInteraction && !Swings.bStartingMiniGame/* && bEnterAnimFinished*/)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if(Swings.bTutorialCancelled)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if(Swings.bMiniGameIsOn)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, Swings);
		Player.BlockCapabilities(CapabilityTags::Collision, Swings);
		Player.BlockCapabilities(CapabilityTags::Movement, Swings);
		Player.BlockCapabilities(n"FindOtherPlayer", Swings);

		Swings.PlayerIsReady(Player);
		
		// if(Player.IsMay())
		// 	Player.ActivateCamera(Swings.MayStartCamera, CameraBlend::Normal(), this, EHazeCameraPriority::High);
		// else
		// 	Player.ActivateCamera(Swings.CodyStartCamera, CameraBlend::Normal(), this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(Swings.bMiniGameIsOn)
		{
			PlayerSwing.bSwinging = true;
		}
		else /*if(PlayerSwing.bCancelledInteraction || Swings.bTutorialCancelled)*/
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, Swings);
			Player.UnblockCapabilities(CapabilityTags::Collision, Swings);
			Player.UnblockCapabilities(CapabilityTags::Movement, Swings);
			Player.UnblockCapabilities(n"FindOtherPlayer", Swings);

			Swings.ResetSwing(PlayerSwing);

			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
		}
	
	}
}