import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;

/**
 * Locally simulates picking up the bomb before we actually
 * know that this should be allowed by the bomb's control side.
 */
class UFlyingBombLocalPreHeldCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingBombHeld");
	default CapabilityDebugCategory = n"FlyingBomb";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 99;

	AFlyingBomb Bomb;
	AClockworkBird Bird;
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter HoldingPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bomb = Cast<AFlyingBomb>(Owner);
		MoveComp = Bomb.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Bomb.LocalWantHeldByBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (Bomb.CurrentState != EFlyingBombState::Idle)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Bomb.LocalWantHeldByBird == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (Bomb.CurrentState != EFlyingBombState::Idle)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird = Bomb.LocalWantHeldByBird;
		Bird.bIsHoldingBomb = true;
		Bomb.RootComponent.AttachToComponent(Bird.HeldBombRoot);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Bomb.HeldByBird == nullptr)
			Bomb.RootComponent.DetachFromParent(bMaintainWorldPosition = true);
		if (Bomb.HeldByBird != Bird)
			Bird.bIsHoldingBomb = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Bomb.VisualRoot.RelativeRotation = FMath::RInterpConstantTo(Bomb.VisualRoot.RelativeRotation, FRotator(), DeltaTime, 180.f);
	}
};