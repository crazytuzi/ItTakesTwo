import Vino.Interactions.OneShotInteraction;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Gifts.GiftDispenserActor;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.CounterWeight.CounterWeightActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Gifts.GiftDispenserWingedPacakgeActor;


class APackageDeliveryInteraction : AOneShotInteraction
{
	UPROPERTY()
	AGiftDispenserActor GiftDispenser;

	UPlayerPickupComponent MayPickup;
	UPlayerPickupComponent CodyPickup;

	UPROPERTY()
	ACounterWeightActor CounterWeightActor;

	AHazePlayerCharacter PlayerDropping;

	TArray<AActor> EntryPoints;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MayPickup = UPlayerPickupComponent::Get(Game::GetMay());
		CodyPickup = UPlayerPickupComponent::Get(Game::GetCody());

		MayPickup.OnPickedUpEvent.AddUFunction(this, n"OnPickedUpPackage");
		CodyPickup.OnPickedUpEvent.AddUFunction(this, n"OnPickedUpPackage");

		MayPickup.OnPutDownEvent.AddUFunction(this, n"OnPlayerDroppedPackage");
		CodyPickup.OnPutDownEvent.AddUFunction(this, n"OnPlayerDroppedPackage");

		DisableInteractionForPlayer(Game::GetMay(), n"PackageDelivery");
		DisableInteractionForPlayer(Game::GetCody(), n"PackageDelivery");

		if (CounterWeightActor != nullptr)
		{
			CounterWeightActor.StateChanged.AddUFunction(this, n"CounterWeightStateChanged");
		}

		GetAttachedActors(EntryPoints);
	}

	UFUNCTION()
	void CounterWeightStateChanged(ECounterWeightState State)
	{
		if (State == ECounterWeightState::IsAtEnd)
		{
			EnableInteraction(n"CounterWeight");
		}

		else
		{
			DisableInteraction(n"CounterWeight");
		}
	}

	UFUNCTION(NotBlueprintCallable, BlueprintOverride)
    void OnTriggerComponentActivated(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
    {
		PlayerDropping = Player;
		
		if (CounterWeightActor != nullptr)
		{
			CounterWeightActor.BlockCapabilities(n"CounterWeight", this);
		}

		FTransform Desiredlocation = GetClosestActor(Player).ActorTransform;

		FHazeDestinationSettings DestinationSettings;
		FHazeDestinationEvents DestinationEvents;

		DestinationSettings.InitializeSmoothTeleport();
		DestinationSettings.ActivateOnActor(Player, Desiredlocation, DestinationEvents);

		Super::OnTriggerComponentActivated(Trigger, Player);
	}

	AActor GetClosestActor(AHazePlayerCharacter Player)
	{
		AActor ClosestCandidate = this;
		float ClosestDistance = BIG_NUMBER;

		for (AActor var : EntryPoints)
		{
			if (Player.ActorLocation.Distance(var.ActorLocation) < ClosestDistance)
			{
				ClosestDistance = Player.ActorLocation.Distance(var.ActorLocation);
				ClosestCandidate = var;
			}
		}

		return ClosestCandidate;
	}

	UFUNCTION(NotBlueprintCallable)
    void AnimationBlendingOut()
    {
		Super::AnimationBlendingOut();

		UPlayerPickupComponent::Get(PlayerDropping).ForceDrop(false);
		UPlayerPickupComponent::Get(PlayerDropping).OnPutDownEvent.AddUFunction(this, n"OnPackagePutDown");

		if (CounterWeightActor != nullptr)
		{
			CounterWeightActor.UnblockCapabilities(n"CounterWeight", this);
		}
	}

	UFUNCTION()
	void OnPackagePutDown(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		if (Cast<AGiftDispenserWingedPackage>(GiftDispenser) != nullptr)
		{
			
		}
		else
		{
			GiftDispenser.CompletedGift();
			GiftDispenser.Gift.DestroyActor();
			UPlayerPickupComponent::Get(PlayerCharacter).OnPutDownEvent.Unbind(this, n"OnPackagePutDown");
		}
	}

	UFUNCTION()
	void OnPlayerDroppedPackage(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		DisableInteractionForPlayer(Player, n"PackageDelivery");
	}

	UFUNCTION()
	void OnPickedUpPackage(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		AGiftDispenserWingedPackage WingedgiftDispenser = Cast<AGiftDispenserWingedPackage>(GiftDispenser);

		if (WingedgiftDispenser != nullptr)
		{
			if (PickupActor == WingedgiftDispenser.Gift || PickupActor == WingedgiftDispenser.Gift2)
			{
				EnableInteractionForPlayer(Player, n"PackageDelivery");	
			}
		}

		else if (PickupActor == GiftDispenser.Gift)
		{
			EnableInteractionForPlayer(Player, n"PackageDelivery");
		}
	}
}