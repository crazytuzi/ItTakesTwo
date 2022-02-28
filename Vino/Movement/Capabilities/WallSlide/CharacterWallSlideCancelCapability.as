import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;
import Vino.Movement.MovementSystemTags;

class UCharacterWallSlideCancelCapability : UHazeCapability
{
	default RespondToEvent(WallslideActivationEvents::Wallsliding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 145;

	default CapabilityDebugCategory = CapabilityTags::Movement;
	UCharacterWallSlideComponent WallDataComp;
	UHazeMovementComponent MoveComp;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		WallDataComp = UCharacterWallSlideComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!WallDataComp.IsSliding())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.WasPushed())
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (IsActioning(ActionNames::Cancel))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!MoveComp.MoveWithLastDelta.IsNearlyZero() && !MoveComp.IsCurrentMoveWithComponent(WallDataComp.PrimitiveSlidingOn))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		WallDataComp.StopSliding(EWallSlideLeaveReason::Cancelled);
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

}
