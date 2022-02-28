import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Jump.AirJumpsComponent;

class UCharacterWallSlideVerticalJumpReattachBlockerCapability : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(MovementSystemTags::WallSlide);

	UCharacterWallSlideComponent WallDataComp;
	UHazeMovementComponent MoveComp;

	UCharacterAirJumpsComponent AirJumpComp;

	default TickGroup = ECapabilityTickGroups::LastMovement;

	int AirJumpsWhenActivated = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		WallDataComp = UCharacterWallSlideComponent::GetOrCreate(Owner);
		AirJumpComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!WallDataComp.JumpOffData.IsValid())
			return EHazeNetworkActivation::DontActivate;

		if (WallDataComp.JumpOffData.Type != EWallSlideJumpOffType::Vertical)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(MovementSystemTags::WallSlideEvaluation, this);

		AirJumpsWhenActivated = AirJumpComp.JumpCharges;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;
	
		if (IsBelowJumpOffPoint())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) const
	{
		Owner.UnblockCapabilities(MovementSystemTags::WallSlideEvaluation, this);
		WallDataComp.JumpOffData.Reset();
	}

	bool IsBelowJumpOffPoint() const
	{
		FVector JumpOffLoc = WallDataComp.JumpOffData.JumpOffLocation;
		if (AirJumpComp.JumpCharges < AirJumpsWhenActivated)
			JumpOffLoc += MoveComp.WorldUp * WallDataComp.Settings.WallslideReactivationBonusHeight;

		FVector VerticalDif = (MoveComp.OwnerLocation - JumpOffLoc).ConstrainToDirection(MoveComp.WorldUp);
		
		return VerticalDif.DotProduct(MoveComp.WorldUp) <= 0.f;
	}
}
