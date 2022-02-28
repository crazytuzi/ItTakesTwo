import Vino.Pickups.PickupActor;

event void FCoinWasPickedUp(AHazePlayerCharacter Player, bool bWasPickedUp);

class APiggyBankCoin : APickupActor
{
	UPROPERTY()
	FCoinWasPickedUp CoinWasPickedUpEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION()
	void DisableCoin()
	{
		for(auto Player : Game::GetPlayers())
			InteractionComponent.DisableForPlayer(Player, n"CoinDisabled");

		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPickedUpDelegate(Player, PickupActor);
		CoinWasPickedUpEvent.Broadcast(Player, true);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPutDownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPutDownDelegate(Player, PickupActor);
		CoinWasPickedUpEvent.Broadcast(Player, false);
	}
}