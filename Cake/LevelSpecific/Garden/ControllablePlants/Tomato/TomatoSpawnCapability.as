import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTags;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

class UTomatoSpawnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	bool bTomatoFullySpawned = false;

	ATomato Tomato;
	UHazeMovementComponent MoveComp;
	UControllablePlantsComponent PlantsComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tomato = Cast<ATomato>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		PlantsComp = UControllablePlantsComponent::Get(Tomato.OwnerPlayer);
	}

	bool CanSpawnTomato() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(TomatoTags::Activate))
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Tomato.bFinishedSpawning)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Tomato.Velocity = FVector::ZeroVector;
		Owner.SetCapabilityAttributeVector(TomatoTags::SlideVelocity, FVector::ZeroVector);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		
		Tomato.SetActorLocation(Tomato.OwnerPlayer.ActorLocation);

		Tomato.SpawnCurve.PlayFromStart();
		Tomato.TomatoRoot.SetWorldRotation(FRotator::ZeroRotator);
		Tomato.SetActorEnableCollision(true);
		Tomato.SetActorHiddenInGame(false);
		bTomatoFullySpawned = false;
		Tomato.bWasDestroyed = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		if (bTomatoFullySpawned)
		{
			Tomato.TomatoFullySpawned();
		}
	}
}
