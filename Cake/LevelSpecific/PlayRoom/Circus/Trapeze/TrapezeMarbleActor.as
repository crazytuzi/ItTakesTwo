import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeTags;

event void FTrapezeMarbleEvent(ATrapezeMarbleActor Marble);
event void FMarbleThrownEvent(AHazePlayerCharacter Player, bool bDispenserThrow);
event void FOnMarbleFlyingTowardsReceptacle(AHazePlayerCharacter PlayerCharacter);

class ATrapezeMarbleActor : APickupActor
{
	UPROPERTY()
	float ValidCatchDistance = 140.f;
	const float CatchDistanceWhenResting = 240.f;

	// Marble is ready to be reset back to the dispenser
	UPROPERTY()
	FTrapezeMarbleEvent OnMarbleReadyForReset;

	UPROPERTY()
	UNiagaraSystem MarbleBreakSystem;

	UPROPERTY()
	FMarbleThrownEvent OnMarbleThrownEvent;

	UPROPERTY()
	FTrapezeMarbleEvent OnMarbleSpawnEvent;

	UPROPERTY()
	FTrapezeMarbleEvent OnMarbleEnteredReceptacle;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DespawnEvent;

	UPROPERTY()
	FOnMarbleFlyingTowardsReceptacle OnMarbleFlyingTowardsReceptacle;

	UMoveProjectileAlongCurveComponent ProjectileAlongCurveComponent;

	private bool bIsAirborne;
	private bool bIsFlyingTowardsDispenser;

	// This should be set whenever marble is ready for pickup
	private bool bCanBePickedUpFromTrapeze = false;

	bool bEnteredReceptacle;
	bool bWasWithinReachOfCatcherSide;

	float LastPutDownTimeStamp;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		Mesh.GenerateOverlapEvents = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ProjectileAlongCurveComponent = UMoveProjectileAlongCurveComponent::GetOrCreate(this);

		Mesh.SetCullDistance(10000.f);

		// Bind delegates
		OnMarbleThrownEvent.AddUFunction(this, n"OnMarbleThrown");
		OnMarbleEnteredReceptacle.AddUFunction(this, n"OnEnteredReceptable");
	}

	UFUNCTION()
	void StopMoving()
	{
		bIsAirborne = false;
		bIsFlyingTowardsDispenser = false;

		ProjectileAlongCurveComponent.Abort();
	}

	bool IsMarbleWithinReach(AHazePlayerCharacter PlayerCharacter)
	{
		float DistanceToMarble = PlayerCharacter.Mesh.GetSocketLocation(n"Spine2").Distance(ActorLocation);
		float Threshold = IsAirborne() ? ValidCatchDistance : CatchDistanceWhenResting;
		if(DistanceToMarble > Threshold)
			return false;

		return true;
	}

	UFUNCTION()
	void SetReadyForPickup()
	{
		bCanBePickedUpFromTrapeze = true;
		OnMarbleSpawnEvent.Broadcast(this);
	}

	// Queried by the Trapeze capability system before attempting to grab
	bool CanBePickedUpFromTrapeze()
	{
		return bCanBePickedUpFromTrapeze;
	}

	// Should be called by TrapezeMarbleThrowCapability
	void LandMarbleAfterThrow()
	{
		// Hide mesh and play particle effect
		SetActorHiddenInGame(true);
		Niagara::SpawnSystemAtLocation(MarbleBreakSystem, ActorLocation);

		UHazeAkComponent::HazePostEventFireForget(DespawnEvent, GetActorTransform());

		StopMoving();

		// Relay the word
		OnMarbleReadyForReset.Broadcast(this);

		// Cleanup
		bCanBePickedUpFromTrapeze = false;
		bWasWithinReachOfCatcherSide = false;
		bIsAirborne = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private bool CanPlayerPickUp(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter) override
	{
		if(!IsReadyForPickUp())
			return false;

		if(PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(TrapezeTags::MarbleCatch))
			return false;

		if(PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(TrapezeTags::MarbleCatchLauncher))
			return false;

		if(IsAirborne())
			return false;

		// Eman TODO: LE Experimentale crap
		// if(!CanPickUpFromPlatform(PlayerCharacter))
		// 	return false;

		return Super::CanPlayerPickUp(TriggerComponent, PlayerCharacter);
	}

	// Eman TODO: LE Experimentale crap
	// bool CanPickUpFromPlatform(AHazePlayerCharacter PlayerCharacter)
	// {
	// 	if(!PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(TrapezeTags::Trapeze))
	// 		return true;

	// 	if(PlayerCharacter.OtherPlayer.GetSquaredDistanceTo(this) >= 200000.f)
	// 		return true;

	// 	return false;
	// }

	bool IsReadyForPickUp()
	{
		return bCanBePickedUpFromTrapeze && ((Time::GameTimeSeconds - LastPutDownTimeStamp) >= 0.5f);
	}

	bool IsAirborne()
	{
		return bIsAirborne;
	}

	bool IsFlyingTowardsDispenser()
	{
		return bIsFlyingTowardsDispenser;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPickedUpDelegate(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor) override
	{
		Super::OnPickedUpDelegate(PlayerCharacter, PickupActor);
		bIsAirborne = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPutDownDelegate(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor) override
	{
		Super::OnPutDownDelegate(PlayerCharacter, PickupActor);
		LastPutDownTimeStamp = Time::GameTimeSeconds;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMarbleThrown(AHazePlayerCharacter PlayerCharacter, bool bDispenserThrow)
	{
		bIsAirborne = true;
		bIsFlyingTowardsDispenser = bDispenserThrow;

		ReEnableInteractionComponent(PlayerCharacter);

		// Remove carry capability shit
		PlayerCharacter.RemoveCapabilitySheet(CarryCapabilitySheet, PlayerCharacter);

		if(HasControl() && bDispenserThrow)
		{
			AHazePlayerCharacter FullscreenPlayer = SceneView::GetFullScreenPlayer();
			if(FullscreenPlayer == nullptr)
				FullscreenPlayer = PlayerCharacter.HasControl() ? PlayerCharacter : PlayerCharacter.OtherPlayer;

			NetFireMarbleFlyingTowardsReceptacleEvent(FullscreenPlayer);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnEnteredReceptable(ATrapezeMarbleActor Marble)
	{
		bEnteredReceptacle = true;
	}

	UFUNCTION(NetFunction)
	void NetFireMarbleFlyingTowardsReceptacleEvent(AHazePlayerCharacter FullscreenPlayer)
	{
		OnMarbleFlyingTowardsReceptacle.Broadcast(FullscreenPlayer);
	}
}