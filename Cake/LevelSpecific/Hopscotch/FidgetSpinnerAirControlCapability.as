import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
class UFidgetSpinnerAirControlCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"FidgetSpinnerAirControlCapability");
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default CapabilityDebugCategory = n"FidgetSpinnerAirControlCapability";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCharacterMovementCapability::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"FidgetSpinnerAirControl"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"FidgetSpinnerAirControl"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UMovementSettings::SetAirControlLerpSpeed(Player, 10000.f, Instigator = this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetCapabilityActionState(n"FidgetSpinnerAirControl", EHazeActionState::Inactive);
		UMovementSettings::ClearAirControlLerpSpeed(Owner, Instigator = this);		
		//UMovementSettings::ClearHorizontalAirSpeed(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// PrintToScreen("HORIZ");
		// UMovementSettings::SetHorizontalAirSpeed(Player, 300.f, this);	
	}
}