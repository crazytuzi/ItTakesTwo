import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;
import Vino.Movement.MovementSystemTags;

class UCharacterLedgeGrabDropCapability : UHazeCapability
{
	default RespondToEvent(LedgeGrabActivationEvents::Grabbing);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::LedgeGrab);
	default CapabilityTags.Add(LedgeGrabTags::Drop);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 10;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UHazeMovementComponent MoveComp;
	ULedgeGrabComponent LedgeGrabComp;
	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		LedgeGrabComp = ULedgeGrabComponent::Get(Owner);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (!(LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Hang) || LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Entering)))
			return EHazeNetworkActivation::DontActivate;

		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		if (MoveComp.WasPushed())
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		if (MoveComp.MoveWithHit.bBlockingHit)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		LedgeGrabComp.LetGoOfLedge(ELedgeReleaseType::LetGo);
		LedgeGrabComp.SetState(ELedgeGrabStates::Drop);
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		LedgeGrabComp.SetState(ELedgeGrabStates::None);
	}
}
