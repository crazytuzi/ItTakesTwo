import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketGroundMovementCapability : UCharacterMovementCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 120;

	AHazePlayerCharacter Player;
	ULarvaBasketPlayerComponent BasketComp;
	ALarvaBasketCage Cage;

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

		if (MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
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

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cage = BasketComp.CurrentCage;
		MoveComp.Velocity = MoveComp.WorldUp * LarvaBasket::JumpImpulse;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"BasketGround");
		MoveCharacter(FrameMove, n"LarvaBasket");
	}
}