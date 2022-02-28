import Vino.Pickups.PickupActor;
import Vino.Pickups.PickupTags;

class UPostThrowCollisionEnablerCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupablePostThrowCollisionEnabler);
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	APickupActor PickupOwner;
	UMeshComponent PickupMesh;

	bool bShouldActivate;
	bool bCapabilityIsDone;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupOwner = Cast<APickupActor>(Owner);
		PickupMesh = UMeshComponent::Get(Owner);

		PickupOwner.OnStoppedMovingAfterThrowEvent.AddUFunction(this, n"OnStoppedMovingAfterThrow");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return bShouldActivate ?
			EHazeNetworkActivation::ActivateLocal :
			EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't re-activate collision profile until mesh stops overlapping with player
		TArray<AActor> OverlappingActors;
		PickupMesh.GetOverlappingActors(OverlappingActors, AHazePlayerCharacter::StaticClass());
		if(OverlappingActors.Num() > 0)
			return;

		bCapabilityIsDone = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bCapabilityIsDone)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PickupMesh.SetCollisionProfileName(PickupOwner.OriginalCollisionProfile);

		bShouldActivate = false;
		bCapabilityIsDone = false;

		PickupOwner.RemoveCapability(UPostThrowCollisionEnablerCapability::StaticClass());
	}

	UFUNCTION(NotBlueprintCallable)
	void OnStoppedMovingAfterThrow()
	{
		bShouldActivate = true;
	}
}