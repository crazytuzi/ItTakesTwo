import Vino.Movement.SplineLock.SplineLockProcessor;
import Vino.Movement.SplineLock.SplineLockComponent;
import Peanuts.Movement.SplineLockStatics;

class ULockCharacterToSplineCapability : UHazeCapability
{
	USplineLockProcessor SplineLockProcessor;

	USplineLockComponent SplineLockComp;
	UHazeBaseMovementComponent MoveComp;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 99;
	default SeperateInactiveTick(ECapabilityTickGroups::BeforeMovement, 100);

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);
		MoveComp = UHazeBaseMovementComponent::GetOrCreate(Owner);
		SplineLockProcessor = USplineLockProcessor();
		SplineLockProcessor.SplineLockComp = SplineLockComp;

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SplineLockComp.IsActiveltyConstraining())
			return EHazeNetworkActivation::DontActivate;

		if (SplineLockComp.ActiveLockType != ESplineLockType::Normal)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SplineLockComp.IsActiveltyConstraining())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SplineLockComp.ActiveLockType != ESplineLockType::Normal)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveComp.UseDeltaProcessor(SplineLockProcessor, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.StopDeltaProcessor(this);

		if (!SplineLockComp.Constrainer.bLockToEnds)
			StopSplineLockMovement(PlayerOwner);
	}

}
