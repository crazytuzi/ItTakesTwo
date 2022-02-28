import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStoneComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;

class UCurlingPlayerShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingShootCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UMagneticPlayerComponent MagnetComp;
	ACurlingStone TargetStone;
	UCurlingPlayerComp PlayerComp;

	const float ShootDelay = 0.15f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UCurlingPlayerComp::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MagnetComp = UMagneticPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{				
		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Shooting)
	        return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::Shooting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration >= ShootDelay)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.CleanupCurrentMovementTrail();
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(IceSkatingTags::IceSkating, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		TargetStone = Cast<ACurlingStone>(PlayerComp.TargetStone);

		if (TargetStone == nullptr)
			return;
		
		UCurlingStoneComponent StoneComp = UCurlingStoneComponent::Get(TargetStone); 
		
		if (StoneComp == nullptr)
			return;

		PlayerComp.HideCurlTutorialPrompt(Player);

		TargetStone.DisablePlayerInteraction();
		TargetStone.MoveComp.ConsumeAccumulatedImpulse();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(IceSkatingTags::IceSkating, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		PlayerComp.PlayerCurlState = EPlayerCurlState::Observing;	

		FVector Impulse = PlayerComp.PlayerShootForwardVector * PlayerComp.CurlingPower;
		TargetStone.MoveComp.Velocity = Impulse;
		TargetStone.InitialImpulseSpeed = Impulse.Size();

		TargetStone.BroadcastEventActivateStoneAndCamera(Player);
		
		Player.PlayForceFeedback(PlayerComp.ForceShootImpact, false, true, NAME_None);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		MagnetComp.DisabledForObjects.Empty();
    }
}