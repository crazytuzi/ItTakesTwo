import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Jump.AirJumpsComponent;
import Rice.Math.MathStatics;
import Vino.Movement.Jump.CharacterJumpBufferComponent;

class UCharacterAirJumpFacingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Jump);
	default CapabilityTags.Add(MovementSystemTags::AirJump);
	default CapabilityTags.Add(CapabilityTags::CharacterFacing);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 140;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"AirJumping"))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"AirJumping"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::CharacterFacing, true);
		UpdateFacingDirection(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::CharacterFacing, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateFacingDirection(21.f);
	}

	void UpdateFacingDirection(float Speed)
	{
		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

		if (!Input.IsNearlyZero())
			MoveComp.SetTargetFacingDirection(Input.GetSafeNormal(), Speed);
		else if (!MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).IsNearlyZero())
			MoveComp.SetTargetFacingDirection(MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal(), Speed);
		else
			MoveComp.SetTargetFacingDirection(Owner.ActorForwardVector, Speed);
	}
}