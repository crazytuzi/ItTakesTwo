import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketBallThrowGroundCapability : UHazeCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	ULarvaBasketPlayerComponent BasketComp;
	UHazeMovementComponent MoveComp;
	ALarvaBasketManager LarvaBasketManager;  

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BasketComp = ULarvaBasketPlayerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		LarvaBasketManager = GetLarvaBasketManager();
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

		if (!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::WeaponFire) &&
			!WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkActivation::DontActivate;

		if (!LarvaBasketGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		ALarvaBasketBall Ball = BasketComp.HeldBall;
		Ball.DetachRootComponentFromParent();
		Ball.ThrowBall(BasketComp.GetThrowOrigin(), BasketComp.GetGroundThrowImpulse());

		BasketComp.HeldBall = nullptr;

		MoveComp.SetSubAnimationTagToBeRequested(n"Throw");

		LarvaBasketPlayThrowBark(Player);
	}
}