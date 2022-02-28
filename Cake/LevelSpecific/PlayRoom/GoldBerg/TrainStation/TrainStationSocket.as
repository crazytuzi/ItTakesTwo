import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.TrainStation.TrainStationFigure;
import Vino.Pickups.PlayerPickupComponent;

event void FPutDownEventSignature(ATrainstationFigure Figure, bool bIsCompatible, AHazePlayerCharacter Player);
event void FPickedupEventSignature(AHazePlayerCharacter Player);
class ATrainstationSocket : AHazeActor
{
	UPROPERTY(RootComponent)
	USceneComponent Root;

	UPROPERTY()
	UHazeCapabilitySheet BlockinputSheet;

	UPROPERTY(DefaultComponent)
	UInteractionComponent Interaction;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase MeshSocket;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PickedFromSocketAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DroppedOnSocketAudioEvent;

	UPROPERTY(DefaultComponent)
	UArrowComponent FaceDirection;
	
	UPROPERTY()
	AHazeActor CompatibleFigure;

	UPROPERTY()
	ATrainstationFigure FigureInSocket;
	TArray<ATrainstationFigure> Figures;

	UPROPERTY()
	FPutDownEventSignature PutdownCompatibleFigure;

	UPROPERTY()
	FPickedupEventSignature PickedUpCompatibleFigure;

	AHazePlayerCharacter PlayerDropping;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Interaction.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		FHazeTriggerCondition TriggerCondition;
		TriggerCondition.bDisplayVisualsWhileDisabled = true;
		TriggerCondition.Delegate.BindUFunction(this, n"CanPlayerInteractWithSocket");
		Interaction.AddTriggerCondition(n"CanPlayerInteractWithSocket", TriggerCondition);

		Interaction.DisableForPlayer(Game::GetCody(),n"Figure");
		Interaction.DisableForPlayer(Game::GetMay(),n"Figure");

		TArray<AActor> Actors;
		Gameplay::GetAllActorsOfClass(ATrainstationFigure::StaticClass(), Actors);

		for (auto actor : Actors)
		{
			Figures.Add(Cast<ATrainstationFigure>(actor));
		}

		for (auto player : Game::GetPlayers())
		{
			UPlayerPickupComponent PlayerPickup = UPlayerPickupComponent::Get(player);
			PlayerPickup.OnPickedUpEvent.AddUFunction(this, n"PickedupFigure");
			PlayerPickup.OnPutDownEvent.AddUFunction(this, n"DroppedFigure");
		}
    }

	UFUNCTION()
	void DroppedFigure(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		Interaction.DisableForPlayer(PlayerCharacter,n"Figure");
	}

	UFUNCTION()
	void PickedupFigure(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		if (Cast<ATrainstationFigure>(PickupableActor) == nullptr)
		{
			return;
		}

		if (PickupableActor == FigureInSocket)
		{
			Interaction.Enable(n"FigureInSocket");
			FigureInSocket.OnPlacedOnFloorEvent.Unbind(this, n"PutDown");
			FigureInSocket.PlayAnimationReverse();

			FigureInSocket = nullptr;
			PickedUpCompatibleFigure.Broadcast(PlayerCharacter);

			UHazeAkComponent::HazePostEventFireForget(PickedFromSocketAudioEvent, PickupableActor.GetActorTransform());

		}

		if (FigureInSocket == nullptr)
		{
			Interaction.EnableForPlayer(PlayerCharacter,n"Figure");	
		}
	}

	UFUNCTION(NotBlueprintCallable)
	bool CanPlayerInteractWithSocket(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		APickupActor CurrentPickup = UPlayerPickupComponent::Get(PlayerCharacter).CurrentPickup;
		if(CurrentPickup == nullptr)
			return false;

		if(!CurrentPickup.IsA(ATrainstationFigure::StaticClass()))
			return false;

		// Don't test sweep if player is too far
		float MinTestDistance = Interaction.ActionShape.SphereRadius * Interaction.ActionShapeTransform.Scale3D.X;
		if(MeshSocket.WorldLocation.Distance(PlayerCharacter.ActorLocation) > MinTestDistance)
			return false;

		// Now check if the path is clear
		FHazeTraceParams Trace;
		Trace.InitWithMovementComponent(PlayerCharacter.MovementComponent);
		Trace.TraceShape = FCollisionShape::MakeBox(CurrentPickup.PickupExtents);

		// Setup ignores
		Trace.IgnoreActor(PlayerCharacter);
		Trace.IgnoreActor(PlayerCharacter.OtherPlayer);
		Trace.IgnoreActor(CurrentPickup);

		Trace.From = CurrentPickup.ActorLocation;
		Trace.To = MeshSocket.WorldLocation + FVector::UpVector * CurrentPickup.PickupExtents.Z;

		FHazeHitResult HitResult;
		return !Trace.Trace(HitResult);
	}

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		ATrainstationFigure Figure = Cast<ATrainstationFigure>(UPlayerPickupComponent::Get(Player).CurrentPickup);

		PlayerDropping = Player;

		Interaction.Disable(n"FigureInSocket");
		FigureInSocket = Figure;

		UPlayerPickupComponent::Get(Player).ForceDropAtLocationWithRotation(MeshSocket.WorldLocation, FaceDirection.WorldRotation, bMovePlayerNextToLocation = false);
		Figure.OnPlacedOnFloorEvent.AddUFunction(this, n"PutDown");
    }

	UFUNCTION()
	void PutDown(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		ATrainstationFigure Pickup = Cast<ATrainstationFigure>(PickupableActor);
		Pickup.PlayAnimation();

		bool IsCompatible;
		IsCompatible = Pickup == CompatibleFigure;

		PutdownCompatibleFigure.Broadcast(Pickup, IsCompatible, PlayerCharacter);

		UHazeAkComponent::HazePostEventFireForget(DroppedOnSocketAudioEvent, PickupableActor.GetActorTransform());

		PlayerCharacter.RemoveCapabilitySheet(BlockinputSheet);

		FigureInSocket.SetActorLocation(MeshSocket.GetWorldLocation());
		FigureInSocket.SetActorRotation(FaceDirection.GetWorldRotation());
	}
}