import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.GroundPound.GroundPoundNames;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Capabilities.GroundPound.GroundPoundSettings;

class UCharacterGroundPoundStandUpCapability : UCharacterMovementCapability
{
	default RespondToEvent(GroundPoundEventActivation::Landed);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Exit);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 14;

	UCharacterGroundPoundComponent GroundPoundComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		float StandupActivationTime = GroundPoundSettings::StandUp.ActivationTime;
		if (!GetAttributeVector(AttributeVectorNames::MovementRaw).IsNearlyZero())
			StandupActivationTime = 0.f;

		if (!GroundPoundComp.IsAllowLandedAction(StandupActivationTime))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		GroundPoundComp.AnimationData.bIsStandingUp = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ActiveDuration >= GroundPoundSettings::StandUp.Duration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		GroundPoundComp.ResetState();
	}

}
