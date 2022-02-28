import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;

class UCurlingPlayerEngagedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerReadyCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent MagnetComp;
	ACurlingStone TargetStone;
	UCurlingPlayerComp PlayerComp;

	const float LerpTime =  0.75f;
	const float EngagingTime = 0.6f;
	
	FRotator Rotation;
	FVector Location;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MagnetComp = UMagneticPlayerComponent::Get(Player);
		PlayerComp = UCurlingPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Engaging)
	        return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration >= EngagingTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetStone = Cast<ACurlingStone>(PlayerComp.TargetStone);

		if (TargetStone == nullptr)
			return;

		TargetStone.bIsControlledByPlayer = true;

		// Capability blocks
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Player.TriggerMovementTransition(this);

		FVector Direction = (TargetStone.ActorLocation - FVector(Player.ActorLocation.X, Player.ActorLocation.Y, TargetStone.ActorLocation.Z)).GetSafeNormal();		
		Location = FVector(TargetStone.ActorLocation.X, TargetStone.ActorLocation.Y, Player.ActorLocation.Z) - (Direction * PlayerComp.EngagedDistance); 
		Rotation = FRotator::MakeFromX(Direction);

		Rotation.Roll = 0.f;
		Rotation.Pitch = 0.f;

		Player.SmoothSetLocationAndRotation(Location, Rotation, LerpTime, LerpTime);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		if (WasActionStarted(ActionNames::Cancel))
		{
			OutParams.AddActionState(n"bCancelled");
			Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		if (DeactivationParams.GetActionState(n"bCancelled"))
			PlayerComp.PlayerCurlState = EPlayerCurlState::Default;
		else
			PlayerComp.PlayerCurlState = EPlayerCurlState::MoveStone;
	}
}