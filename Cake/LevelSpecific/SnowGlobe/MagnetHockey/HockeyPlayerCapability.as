import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuckStatics;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuckComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuck;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;

class UHockeyPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHockeyPlayerComp PlayerComp;
	UMagneticPlayerComponent MagnetComp;
	UHockeyPuckComponent HockeyPuckComp;

	FVector MagnetTarget;

	float MagnetPower = 5500.f;

	float MaxPushDistance = 1550.f;

	float MaxMagnetDistance = 2800.f;

	float CurrentMagnetDistance;

	float CurrentTimer;

	float MaxTimer = 0.7f;

	float MinDistance = 2000.f;

	bool bHaveStruck;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
		MagnetComp = UMagneticPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		// if (MagnetComp.GetActivatedMagnet() == nullptr)
		// 	return EHazeNetworkActivation::DontActivate;

		// if (!MagnetComp.ActivatedMagnet.Owner.ActorHasTag(HockeyPuckTags::HockeyPuck))
		// 	return EHazeNetworkActivation::DontActivate;

		// if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
		// 	return EHazeNetworkActivation::DontActivate;

		// if (PlayerComp.bHasCompletedPush)
		// 	return EHazeNetworkActivation::DontActivate;

        // return EHazeNetworkActivation::ActivateLocal;
        return EHazeNetworkActivation::DontActivate;
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		// if (MagnetComp.GetActivatedMagnet() != nullptr)
		// 	return EHazeNetworkDeactivation::DontDeactivate;

		// if (!PlayerComp.bHasCompletedPush)
		// 	return EHazeNetworkDeactivation::DontDeactivate;

		// return EHazeNetworkDeactivation::DontDeactivate;
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Player.BlockCapabilities(CameraTags::ChaseAssistance, this);
		// TargetHockeyPuck = Cast<AHockeyPuck>(MagnetComp.ActivatedMagnet.Owner);

		// if (PlayerComp.HockeyPuck == nullptr)
		// 	return;

		// bHaveStruck = false;

		// FHazeSlotAnimSettings AnimSettings;
		// AnimSettings.BlendTime = 0.25f;
		// AnimSettings.bLoop = false;
		// AnimSettings.PlayRate = 1.5f;

		// Player.PlaySlotAnimation(PlayerComp.AnimSequence, AnimSettings); 

		// CurrentTimer = MaxTimer;

		// HockeyPuckComp = UHockeyPuckComponent::Get(PlayerComp.HockeyPuck);

		// HockeyPuckComp.PlayerArray.Add(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);

		// HockeyPuckComp.PlayerArray.Remove(Player);

		// CurrentMagnetDistance = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// if (PlayerComp.HockeyPuck == nullptr)
		// 	return;

		// FVector TargetDirection = PlayerComp.HockeyPuck.ActorLocation - Player.ActorLocation;
		// CurrentMagnetDistance =  TargetDirection.Size();

		// // if (CurrentMagnetDistance >= MaxMagnetDistance)
		// // 	MagnetComp.DeactivateMagnetLockon(Player);

		// CurrentTimer -= DeltaTime;

		// if (CurrentTimer <= 0.3f && !bHaveStruck)
		// {
		// 	PushTarget();
		// 	bHaveStruck = true;
		// }

		// if (CurrentTimer <= 0.f)
		// {
		// 	PlayerComp.bHasCompletedPush = true;
		// }
	}

	UFUNCTION()
	void PushTarget()
	{
		// UHazeMovementComponent PuckMoveComp = UHazeMovementComponent::Get(PlayerComp.HockeyPuck);

		// if (PuckMoveComp == nullptr)
		// 	return;

		// float Distance = (PlayerComp.HockeyPuck.ActorLocation - Player.ActorLocation).Size();

		// if (Distance <= MinDistance)
		// {
		// 	FVector Direction = (PlayerComp.HockeyPuck.ActorLocation - Player.ActorLocation).GetSafeNormal();
		// 	float Multiplier = Distance / MinDistance;
		// 	Multiplier = 1 - Multiplier;

		// 	float Power = MagnetPower * Multiplier;

		// 	PuckMoveComp.AddImpulse(Direction * Power);

		// 	FVector ForwardAmount = Player.ActorForwardVector * 200.f;
		// 	FVector Location = ForwardAmount + Player.ActorLocation;

		// 	if (Player == Game::GetMay())
		// 		Niagara::SpawnSystemAtLocation(PlayerComp.MagnetSlamSystemMay, Location, Player.ActorRotation);
		// 	else
		// 		Niagara::SpawnSystemAtLocation(PlayerComp.MagnetSlamSystemCody, Location, Player.ActorRotation);
		// }


	}
}