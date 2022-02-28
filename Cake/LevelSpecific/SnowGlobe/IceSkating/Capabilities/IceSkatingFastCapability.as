import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingFastCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 130;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	UHazeMovementComponent MoveComp;
	FIceSkatingFastSettings FastSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

	    FVector Velocity = MoveComp.Velocity;
	    if (Velocity.Size() < FastSettings.Threshold)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
	    FVector Velocity = MoveComp.Velocity;
	    if (Velocity.Size() < FastSettings.Threshold)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		SkateComp.bIsFast = true;
		SkateComp.OnFastChanged(true);

		Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		SkateComp.CallOnStartFastMovementEvent();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		SkateComp.bIsFast = false;
		SkateComp.OnFastChanged(false);

		Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		SkateComp.CallOnEndFastMovementEvent();
	}
}