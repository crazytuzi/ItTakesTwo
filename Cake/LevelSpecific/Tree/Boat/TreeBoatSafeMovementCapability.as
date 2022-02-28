import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Boat.TreeBoatComponent;
import Peanuts.Movement.DeltaProcessor;

class UTreeBoatDeltaProcessor : UDeltaProcessor
{
	AActor LockToActor;

	float MaxDistance = 742.f;

	FVector Derp(FVector CurrentLocation, FVector WantedDelta)
	{
		FVector WantedLocation = CurrentLocation + WantedDelta;
		FVector FromPointVector = (WantedLocation - LockToActor.GetActorLocation());
		
		if (FromPointVector.Size() <= MaxDistance)
			return WantedDelta;

		FVector NewWantedLocation = LockToActor.GetActorLocation() + FromPointVector.GetSafeNormal() * MaxDistance;
		FVector NewDelta = NewWantedLocation - CurrentLocation;
		return NewDelta;
	}

	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTimeStep) override
	{
		SolverState.RemainingDelta = Derp(SolverState.CurrentLocation, SolverState.RemainingDelta);
	}
}

class UTreeBoatSafeMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"TreeBoat");
	default CapabilityTags.Add(n"TreeBoatConstrain");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default TickGroupOrder = 101;

	AHazePlayerCharacter Player;

	UTreeBoatDeltaProcessor DeltaProcessor;

	UTreeBoatComponent TreeBoatComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		TreeBoatComponent = UTreeBoatComponent::Get(Owner);

		DeltaProcessor = UTreeBoatDeltaProcessor();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkActivation::DontActivate;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveComp.UseDeltaProcessor(DeltaProcessor, this);
		DeltaProcessor.LockToActor = TreeBoatComponent.ActiveTreeBoat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.StopDeltaProcessor(this);
	}

}
