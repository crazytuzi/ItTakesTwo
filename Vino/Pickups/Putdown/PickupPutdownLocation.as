
import Vino.Interactions.InteractionComponent;
import Vino.Pickups.PlayerPickupComponent;
import Vino.Pickups.PickupActor;

struct FObjectPlacedInfo
{
	// The player that placed the object.
	UPROPERTY()
	AHazePlayerCharacter PlayerCharacter;

	// The object that was placed on this point
	UPROPERTY()
	APickupActor PlacedObject;

	// The point that the object was placed on
	UPROPERTY()
	APickupPutdownLocation PutdownLocation;
}

event void FOnObjectPlaced(FObjectPlacedInfo ObjectPlacedInfo);

/*
A point in space that a PickupActor can be placed on.
*/

class APickupPutdownLocation : AHazeActor
{
	// Only allow PickupActors of this type to be placed. If empty, allow everything to be placed.
	UPROPERTY()
	TArray<TSubclassOf<AActor> > ClassFilter;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComponent;

	UPROPERTY()
	FOnObjectPlaced OnObjectPlaced;

	APickupActor CurrentlyPlacedActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeTriggerCondition TriggerCondition;
		TriggerCondition.Delegate.BindUFunction(this, n"HandleTriggerCondition");

		// TODO: WTF??
		InteractionComponent = UInteractionComponent::Get(this);

		InteractionComponent.AddTriggerCondition(n"HandleTriggerCondition", TriggerCondition);

		InteractionComponent.OnActivated.AddUFunction(this, n"HandleActivateInteraction");
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnObjectPlaced(FObjectPlacedInfo ObjectPlacedInfo) {}


	UFUNCTION()
	bool HandleTriggerCondition(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		if(IsOccupied())
		{
			return false;
		}

		UPlayerPickupComponent PickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);

		if(PickupComponent == nullptr)
		{
			return false;
		}

		if(!PickupComponent.IsHoldingObject())
		{
			return false;
		}

		AActor HoldingObject = PickupComponent.CurrentPickup;

		if(!IsValidActor(HoldingObject))
		{
			return false;
		}

		return true;
	}

	UFUNCTION()
	void HandleActivateInteraction(UInteractionComponent InteractionComponent, AHazePlayerCharacter PlayerCharacter)
	{
		PlayerCharacter.SetCapabilityAttributeObject(PickupTags::PutdownTargetObject, this);
		PlayerCharacter.SetCapabilityActionState(PickupTags::PutdownOnPointCapability, EHazeActionState::ActiveForOneFrame);
	}

	void HandlePlayerPlacedObject(AHazePlayerCharacter PlayerCharacter)
	{
		UPlayerPickupComponent PickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);

		if(PickupComponent == nullptr)
		{
			devEnsure(false, "No pickup component present on player.");
			return;
		}

		if(!PickupComponent.IsHoldingObject())
		{
			return;
		}

		APickupActor PickupActor = Cast<APickupActor>(PickupComponent.CurrentPickup);

		if(PickupActor == nullptr)
		{
			devEnsure(false, "Object that the player is holding is not type APickupActor");
			return;
		}

		FObjectPlacedInfo ObjectPlacedInfo;
		ObjectPlacedInfo.PlacedObject = PickupActor;
		ObjectPlacedInfo.PlayerCharacter = PlayerCharacter;
		ObjectPlacedInfo.PutdownLocation = this;

		PickupActor.DetachFromActor(EDetachmentRule::KeepWorld);
		PickupActor.SetActorLocation(ActorLocation);
		PickupActor.CleanupAfterPutdown();

		BP_OnObjectPlaced(ObjectPlacedInfo);
		OnObjectPlaced.Broadcast(ObjectPlacedInfo);

		PickupComponent.ForceDrop(false);
		PlayerCharacter.PlaySlotAnimation(Animation = PickupComponent.CurrentPickupDataAsset.PutDownAnimation);
		CurrentlyPlacedActor = PickupActor;
		CurrentlyPlacedActor.OnPickedUpEvent.AddUFunction(this, n"HandlePickedUp");
	}

	UFUNCTION(BlueprintPure)
	bool IsOccupied() const
	{
		return CurrentlyPlacedActor != nullptr;
	}

	// Called if the object was placed on this point and later picked up again.
	UFUNCTION()
	void HandlePickedUp(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		if(PickupActor != CurrentlyPlacedActor)
		{
			return;
		}

		CurrentlyPlacedActor.OnPickedUpEvent.UnbindObject(this);
		CurrentlyPlacedActor = nullptr;
	}

	bool IsValidActor(AActor ActorToCheck) const
	{
		if(ActorToCheck == nullptr)
			return false;

		if(ClassFilter.Num() == 0)
		{
			return true;
		}

		for(TSubclassOf<AActor> ClassType : ClassFilter)
		{
			if(ActorToCheck.IsA(ClassType))
			{
				return true;
			}
		}

		return false;
	}
}

