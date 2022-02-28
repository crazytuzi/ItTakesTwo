
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

// This capability moves the swarm root after we've copied
// another swarms pose. It is important that this happens 
// the tick after the copy -- before animation ticks

// The Swarm proxy will spring the bones to the location after this is done

class USwarmMoveRootDeferredCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmMoveRootDeferred");

	// Befor movement means before animation has ticked
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	ASwarmActor SwarmActor = nullptr;
	USwarmMovementComponent MoveComp = nullptr;
	USwarmSkeletalMeshComponent SkelMeshComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = USwarmMovementComponent::Get(Owner);
		SkelMeshComp = USwarmSkeletalMeshComponent::Get(Owner);
		SwarmActor = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) 
	{
		FTransform DesiredTransform;
		DesiredTransform.SetLocation(GetAttributeVector(n"DefMoveLoc"));
		FVector R = GetAttributeVector(n"DefMoveRot");
		DesiredTransform.SetRotation(FRotator::MakeFromEuler(R));
		DesiredTransform.SetScale3D(GetAttributeVector(n"DefMoveScale"));
		SwarmActor.SetActorTransform(DesiredTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) 
	{
		Owner.RemoveCapability(USwarmMoveRootDeferredCapability::StaticClass());
	}

}
















