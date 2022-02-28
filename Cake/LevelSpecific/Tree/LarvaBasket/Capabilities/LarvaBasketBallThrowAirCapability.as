import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketBallThrowAirCapability : UCharacterMovementCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	ULarvaBasketPlayerComponent BasketComp;
	ALarvaBasketManager LarvaBasketManager;  

	float Timer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		BasketComp = ULarvaBasketPlayerComponent::Get(Owner);
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

		if (!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump) &&
			!WasActionStarted(ActionNames::WeaponFire) &&
			!WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkActivation::DontActivate;

		if (!LarvaBasketGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (Timer > LarvaBasket::ThrowHoverDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddVector(n"ThrowLocation", Player.ActorLocation);

		float Charge = Math::GetPercentageBetweenClamped(LarvaBasket::ThrowTimeMin, LarvaBasket::ThrowTimeMax, BasketComp.AirTime);
		Params.AddValue(n"Charge", Charge);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		float Charge = Params.GetValue(n"Charge");
		FVector Impulse = FMath::Lerp(LarvaBasket::BallImpulseAir_Min, LarvaBasket::BallImpulseAir_Max, Charge);

		FTransform ThrowOrigin = BasketComp.GetThrowOrigin();
		if (!HasControl())
			ThrowOrigin.Location = Params.GetVector(n"ThrowLocation");

		ALarvaBasketBall Ball = BasketComp.HeldBall;
		Ball.DetachRootComponentFromParent();
		Ball.ThrowBall(ThrowOrigin, BasketComp.GetAirThrowImpulse());

		BasketComp.OnThrowBall();
		BasketComp.HeldBall = nullptr;
		MoveComp.Velocity *= 0.2f;

		Timer = 0.f;

		LarvaBasketPlayThrowBark(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Timer += DeltaTime;
		float GravityForce = FMath::Lerp(LarvaBasket::ThrowHoverGravity, LarvaBasket::JumpGravity, Timer / LarvaBasket::ThrowHoverDuration);

		FVector Velocity = MoveComp.Velocity;
		Velocity -= MoveComp.WorldUp * GravityForce * DeltaTime;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"BasketThrow");
		FrameMove.ApplyVelocity(Velocity);
		FrameMove.OverrideStepDownHeight(0.f);

		MoveCharacter(FrameMove, n"LarvaBasket", n"Throw");
	}
}
