import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketAirMovementCapability : UCharacterMovementCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 110;

	AHazePlayerCharacter Player;
	ULarvaBasketPlayerComponent BasketComp;

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

		if (MoveComp.IsGrounded())
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
		// Print("AirMove");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Print("Grounded");
		BasketComp.AirTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		BasketComp.AirTime += DeltaTime;
		FVector GravityForce = -MoveComp.WorldUp * LarvaBasket::JumpGravity;

		FVector Velocity = MoveComp.Velocity;
		Velocity += GravityForce * DeltaTime;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"BasketAir");
		FrameMove.ApplyVelocity(Velocity);
		FrameMove.OverrideStepDownHeight(0.f);

		MoveCharacter(FrameMove, n"LarvaBasket", n"AirMovement");

		if (BasketComp.HeldBall != nullptr)
		{
			auto Drawer = BasketComp.HeldBall.TrajectoryDrawer;

			Drawer.DrawTrajectory(
				BasketComp.GetThrowOrigin().Location,
				1600.f,
				BasketComp.GetAirThrowImpulse(),
				LarvaBasket::BallGravity,
				10.f,
				FLinearColor::White
			);
		}
	}
}