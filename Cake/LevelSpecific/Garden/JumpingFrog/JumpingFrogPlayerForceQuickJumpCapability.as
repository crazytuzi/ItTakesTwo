import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;


class UJumpingFrogPlayerForceQuickJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	//default CapabilityTags.Add(ActionNames::WeaponAim);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 49;

	AHazePlayerCharacter Player;
	UJumpingFrogPlayerRideComponent RideComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RideComponent = UJumpingFrogPlayerRideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(RideComponent.Frog == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// You can quickforce the dash with X
		if(IsActioning(ActionNames::MovementDash))
			return EHazeNetworkActivation::ActivateLocal;

		if(!RideComponent.Frog.bIsQuickJumping)
		 	return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;
	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RideComponent.Frog.ForceQuickJumpTimeLeft = 0.26f;
		if(WasActionStarted(ActionNames::MovementDash))
			RideComponent.Frog.CurrentMovementDelay -= 0.12f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}
}