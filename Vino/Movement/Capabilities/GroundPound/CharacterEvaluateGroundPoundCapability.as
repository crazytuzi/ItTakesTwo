import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Components.MovementComponent;

class UCharacterEvaluateGroundPoundCapability : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Start);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 110;

	UHazeMovementComponent MoveComp;
	UCharacterGroundPoundComponent GroundPoundComp;
	AHazePlayerCharacter PlayerOwner = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::None))
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementGroundPound))
			return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		GroundPoundComp.SetToWantToActivate();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!GroundPoundComp.WantsToActive())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		GroundPoundComp.ResetActivation();
	}

}
