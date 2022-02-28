import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketJumpCapability : UCharacterMovementCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ULarvaBasketPlayerComponent BasketComp;

	float Duration = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		BasketComp = ULarvaBasketPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (BasketComp.HeldBall == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if (!LarvaBasketGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.BecameGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Duration > LarvaBasket::JumpHoldTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		MoveComp.Velocity = MoveComp.WorldUp * LarvaBasket::JumpImpulse;
		Duration = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Print("Jumped Deactivate");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Duration += DeltaTime;
		FVector GravityForce = -MoveComp.WorldUp * LarvaBasket::JumpHoldGravityScale * LarvaBasket::JumpGravity;

		FVector Velocity = MoveComp.Velocity;
		Velocity += GravityForce * DeltaTime;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"BasketJump");
		FrameMove.ApplyVelocity(Velocity);
		FrameMove.OverrideStepDownHeight(0.f);

		MoveCharacter(FrameMove, n"LarvaBasket", n"Jump");
	}
}