import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceComponent;

event void FOnIceRaceCheckpointTriggered(AIceRaceCheckpoint Checkpoint, AHazePlayerCharacter Player);

class AIceRaceCheckpoint : AHazeActor
{
	UPROPERTY()
	FOnIceRaceCheckpointTriggered OnIceRaceCheckpointTriggered;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float CheckpointWidth = 1500.f;

	UPROPERTY()
	UNiagaraSystem CheckpointEffect;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftPole;
	default LeftPole.SetRelativeLocation(FVector(0.f, -CheckpointWidth * 0.5f, 0.f));

	UPROPERTY(DefaultComponent)
	USceneComponent RightPole;
	default RightPole.SetRelativeLocation(FVector(0.f, CheckpointWidth * 0.5f, 0.f));

	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerBox;
	default TriggerBox.SetBoxExtent(FVector(200.f, CheckpointWidth * 0.5f, 1000.f));

	UPROPERTY()
	AIceRaceCheckpoint NextCheckpoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Setup Owner
		if (Owner != Game::GetCody())
			SetOwner(Game::GetMay());

		// Set Primitives and Niagara to render only for the Player Owning the Checkpoint
		AHazePlayerCharacter OwningPlayer = Cast<AHazePlayerCharacter>(Owner);

		TArray<UPrimitiveComponent> PrimitiveComponents;
		GetComponentsByClass(PrimitiveComponents);

		for (auto PrimitiveComponent : PrimitiveComponents)
		{
			PrimitiveComponent.SetRenderedForPlayer(OwningPlayer.OtherPlayer, false);
		}

		TArray<UNiagaraComponent> NiagaraComponents;
		GetComponentsByClass(NiagaraComponents);

		for (auto NiagaraComponent : NiagaraComponents)
		{
			NiagaraComponent.SetRenderedForPlayer(OwningPlayer.OtherPlayer, false);
		}

		TriggerBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		/*
		FString NextCheckpointString = "No Checkpoint";

		if (NextCheckpoint != nullptr)
			NextCheckpointString = NextCheckpoint.Name;

		Print("Checkpoint: " + Name + " -> " + NextCheckpointString + " | Owner: " + Owner.Name, 0.f, FLinearColor::Yellow);
		*/
	}

	UFUNCTION()
	void ActivateCheckpoint()
	{
		if (IsActorDisabled())
			EnableActor(this);
	}

	UFUNCTION()
	void DeactivateCheckpoint()
	{
		if (!IsActorDisabled())
			DisableActor(this);
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr || Player != Owner)
			return;

		OnIceRaceCheckpointTriggered.Broadcast(this, Player);
	}
}