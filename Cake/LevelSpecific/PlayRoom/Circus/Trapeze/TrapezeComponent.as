import Vino.Pickups.PickupActor;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeTags;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeMarbleActor;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeAnimationDataComponent;
import Vino.Pickups.PlayerPickupComponent;

class UTrapezeComponent : UActorComponent
{
	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PickupComponent;
	UPlayerPickupComponent OtherPlayerPickupComponent;

	private AActor Trapeze;
	ATrapezeMarbleActor Marble;

	UTrapezeComponent OtherPlayerTrapezeComponent;

	UHazeCapabilitySheet TrapezeCapabilitySheet;

	FVector TargetDispenserLocation;
	private float InitialDistanceToDispenser;

	bool bJustThrewMarble;
	bool bJustCaughtMarble;

	bool bStartCatching;

	// Set by actor and read by trapeze swing capability
	private bool bPlayerIsOnSwing;

	// Set by swing capability and read by unmount capability
	private bool bPlayerWantsOut;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
		OtherPlayerPickupComponent = UPlayerPickupComponent::Get(PlayerOwner.OtherPlayer);

		OtherPlayerTrapezeComponent = UTrapezeComponent::GetOrCreate(PlayerOwner.OtherPlayer);

		PickupComponent.OnPickedUpEvent.AddUFunction(this, n"OnObjectPickedUp");
		PickupComponent.OnPutDownEvent.AddUFunction(this, n"OnObjectDropped");
		PickupComponent.OnThrownEvent.AddUFunction(this, n"OnObjectDropped");
	}

	// Called by TrapezeActor when player interaction starts
	void Initialize(AActor TrapezeActor, UHazeCapabilitySheet CapabilitySheet, FVector TargetDispenserWorldLocation)
	{
		Trapeze = TrapezeActor;
		TrapezeCapabilitySheet = CapabilitySheet;

		// Get marble pickupable (if holding)
		AActor CurrentPickup = PickupComponent.CurrentPickup;
		if(CurrentPickup != nullptr)
			Marble = Cast<ATrapezeMarbleActor>(PickupComponent.CurrentPickup);

		// Add capability sheet
		PlayerOwner.AddCapabilitySheet(TrapezeCapabilitySheet, EHazeCapabilitySheetPriority::Interaction, this);

		TargetDispenserLocation = TargetDispenserWorldLocation;
		InitialDistanceToDispenser = GetDistanceToTargetDispenser();
	}

	// Should be called by TrapezeUnmountCapability when it's done
	void Finalize()
	{
		PlayerOwner.RemoveCapabilitySheet(TrapezeCapabilitySheet, this);

		TrapezeCapabilitySheet = nullptr;
		Trapeze = nullptr;
		Marble = nullptr;

		bPlayerIsOnSwing = false;
		bPlayerWantsOut = false;
	}

	void RequestTrapezeLocomotion(UTrapezeAnimationDataComponent& AnimationDataComponent, float SwingBlendSpaceValue)
	{
		// For some reason the component can be null during first frame when playing over network
		if(AnimationDataComponent == nullptr)
			return;

		bool bShouldInvertBS = PlayerOwner.IsAnyCapabilityActive(TrapezeTags::CatcherThrow);
		AnimationDataComponent.SwingValue = bShouldInvertBS ? -SwingBlendSpaceValue : SwingBlendSpaceValue;
		AnimationDataComponent.bHasMarble = PlayerHasMarble();

		FHazeRequestLocomotionData LocomotionDataRequest;
		LocomotionDataRequest.AnimationTag = n"Trapeze";

		PlayerOwner.RequestLocomotion(LocomotionDataRequest);
	}

	UFUNCTION()
	void OnObjectPickedUp(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		Marble = Cast<ATrapezeMarbleActor>(PickupActor);
	}

	UFUNCTION()
	void OnObjectDropped(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		if(Marble == PickupActor)
			Marble = nullptr;
	}

	bool IsMarbleWithinReach()
	{
		ATrapezeMarbleActor MarbleActor = nullptr;
		return GetMarbleWithinReach(MarbleActor);
	}

	bool GetMarbleWithinReach(ATrapezeMarbleActor& MarbleActor) const
	{
		TArray<UPrimitiveComponent> OverlappingComponents;
		PlayerOwner.GetOverlappingComponents(OverlappingComponents);

		for(auto OverlappingComponent : OverlappingComponents)
		{
			if(OverlappingComponent.Owner == nullptr)
				continue;

			if(OverlappingComponent.Owner.IsA(ATrapezeMarbleActor::StaticClass()))
			{
				MarbleActor = Cast<ATrapezeMarbleActor>(OverlappingComponent.Owner);
				if(!MarbleActor.IsMarbleWithinReach(PlayerOwner))
					return false;

				// Make sure we're not stealing marble from other player
				if(!MarbleActor.IsPickedUp())
					return true;

				MarbleActor = nullptr;
				return false;
			}
		}

		return false;
	}

	AActor GetTrapezeActor() property
	{
		return Trapeze;
	}

	bool PlayerHasMarble() const
	{
		// Eman TODO: Do we need to make sure the player is holding a
		// specific type of pickup actor? Tag marble, maybe?
		return Marble != nullptr;
	}

	// ooh lah lah ;)
	UFUNCTION(BlueprintPure)
	bool IsSwinging() const
	{
		return PlayerOwner.IsAnyCapabilityActive(TrapezeTags::Swing);
	}

	UFUNCTION(BlueprintPure)
	bool OtherPlayerIsSwinging() const
	{
		return OtherPlayerTrapezeComponent.IsSwinging();
	}

	UFUNCTION(BlueprintPure)
	bool BothPlayersAreSwinging() const
	{
		return IsSwinging() && OtherPlayerIsSwinging();
	}

	bool PlayerCanThrowMarble()
	{
		if(!IsSwinging())
			return false;

		if(!PlayerHasMarble())
			return false;

		return true;
	}

	bool PlayerCanCatchMarble()
	{
		if(!IsSwinging())
			return false;

		if(PlayerHasMarble())
			return false;

		if(bJustThrewMarble)
			return false;

		ATrapezeMarbleActor MarbleActor;
		if(!GetMarbleWithinReach(MarbleActor))
			return false;

		if(!MarbleActor.CanBePickedUpFromTrapeze())
			return false;

		if(OtherPlayerPickupComponent.CurrentPickup == MarbleActor)
			return false;

		return true;
	}

	float GetDistanceToTargetDispenser() property
	{
		return PlayerOwner.Mesh.GetSocketLocation(n"Spine2").Distance(TargetDispenserLocation);
	}

	bool ShouldReachForMarble(ATrapezeMarbleActor MarbleActor, bool bIsCatchingEnd)
	{
		if(MarbleActor.IsPickedUp())
			return false;

		if(!IsSwinging())
			return false;

		// Different params for different trapeze roles
		if(bIsCatchingEnd)
		{
			if(!MarbleActor.IsAirborne())
				return false;

			if(MarbleActor.IsFlyingTowardsDispenser())
				return false;

			return true;
		}
		else
		{
			if(MarbleActor.IsAirborne())
				return false;

			if(!MarbleActor.IsReadyForPickUp())
				return false;

			if(MarbleActor.IsFlyingTowardsDispenser())
				return false;

			if(MarbleActor.bEnteredReceptacle)
				return false;

			return true;
		}
	}

	bool DispenserIsWithinThrowRange()
	{
		return (GetDistanceToTargetDispenser() / InitialDistanceToDispenser) < 0.8f;
	}

	void SetPlayerIsOnSwing(bool bIsOnSwing) { bPlayerIsOnSwing = bIsOnSwing; }
	bool PlayerIsOnSwing() { return bPlayerIsOnSwing; }

	void SetPlayerWantsOut(bool bWantsOut) { bPlayerWantsOut = bWantsOut; }
	bool PlayerWantsOut() { return bPlayerWantsOut; }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		PickupComponent.OnPickedUpEvent.Unbind(this, n"OnObjectPickedUp");
		PickupComponent.OnPutDownEvent.Unbind(this, n"OnObjectDropped");
		PickupComponent.OnThrownEvent.Unbind(this, n"OnObjectDropped");
	}
}