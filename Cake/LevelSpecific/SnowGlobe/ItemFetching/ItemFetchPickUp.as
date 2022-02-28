import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchPlayerComp;

enum EPickUpState
{
	Default,
	Recieved,
	Complete
};

class AItemFetchPickUp : APickupActor
{
	EPickUpState PickUpState; 

	FVector DestinationLoc;
	FRotator DestinationRot;

	bool bIsGrounded;

	// float MinDistance;

	UPROPERTY(Category = "Capabilities")
	TSubclassOf<UHazeCapability> Capability;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		AddCapability(Capability);

		OnPickedUpEvent.AddUFunction(this, n"GroundedFalse");
		OnPutDownEvent.AddUFunction(this, n"GroundedTrue");
	}

	UFUNCTION()
	void GroundedTrue(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		UItemFetchPlayerComp PlayerComp = UItemFetchPlayerComp::Get(PlayerCharacter);

		PlayerComp.bHoldingItem = false;

		bIsGrounded = true;

		float DistanceFromDestination = (DestinationLoc - ActorLocation).Size();

		if (DistanceFromDestination <= 300.f)
		{
			SwitchOffPickingUp();
			PickUpState = EPickUpState::Recieved;
		}
	}

	UFUNCTION()
	void GroundedFalse(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		UItemFetchPlayerComp PlayerComp = UItemFetchPlayerComp::Get(PlayerCharacter);

		PlayerComp.bHoldingItem = true;

		bIsGrounded = false;
	}

	UFUNCTION()
	void SwitchOffPickingUp()
	{
		bCodyCanPickUp = false;
		bMayCanPickUp = false;
	}
}