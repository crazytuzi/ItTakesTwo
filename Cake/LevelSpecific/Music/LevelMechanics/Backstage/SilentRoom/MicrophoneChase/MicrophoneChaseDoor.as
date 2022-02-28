import Peanuts.ButtonMash.ButtonMashStatics;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;
import Vino.Interactions.InteractionComponent;

import void SetMicrophoneChaseDoor(AHazeActor, AMicrophoneChaseDoor) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent";
import bool HasCharacterMicrphoneChaseComponent(AHazeActor) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent";
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseManager;

event void FMicrophoneChaseDoorSignature(bool bInteracted);

class AMicrophoneChaseDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent AttachComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartInteractEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MoveDoorEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopInteractEvent;

	UPROPERTY(DefaultComponent, Attach = AttachComp)
	USkeletalMeshComponent PreviewMesh;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default PreviewMesh.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComponent;

	UPROPERTY()
	AMicrophoneChaseManager MicrophoneChaseManager;

	// Sent when a player has interacted with the door on crumb activation
	UPROPERTY()
	FMicrophoneChaseDoorSignature InteractedWithDoor;

	UPROPERTY()
	FMicrophoneChaseDoorSignature ButtonMashCompleted;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedProgress;

	UPROPERTY()
	bool bIsMirrored = false;
	
	bool bDoorShouldClose = false;

	bool bReleasePlayer = false;

	float RelativeLocationOffset = 100.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::GetPlayers())
			InteractionComponent.DisableForPlayer(Player, n"DisabledOnStart");
		
		SetupInteractionComponent();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.SetRelativeLocation(FMath::VInterpConstantTo(MeshRoot.RelativeLocation, TargetLocation, DeltaTime, 100.f));
	}

	void StartOpeningDoor(AHazePlayerCharacter Player)
	{
		InteractedWithDoor.Broadcast(true);
		MicrophoneChaseManager.OnDoorInteraction(Player);
	}

	void OnDoorClosed()
	{
		NetOnDoorClosed();
	}

	UFUNCTION(NetFunction)
	private void NetOnDoorClosed()
	{
		ButtonMashCompleted.Broadcast(true);
		MicrophoneChaseManager.OnClosedDoor();
	}

	UFUNCTION()
	void CloseDoor()
	{
		SetActorHiddenInGame(true);
		DoorMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void ActivateChaseDoorInteractPoints()
	{
		// for (auto Player : Game::GetPlayers())
		// 	InteractionComponent.EnableForPlayer(Player, n"DisabledOnStart");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	bool IsDoorClosed() const
	{
		return SyncedProgress.Value >= 1.0f;
	}

	void SetupInteractionComponent()
	{
		FHazeTriggerCondition TriggerCondition;
		TriggerCondition.Delegate.BindUFunction(this, n"CanPlayerInteract");
		InteractionComponent.AddTriggerCondition(n"CanPlayerInteract", TriggerCondition);

		InteractionComponent.OnActivated.AddUFunction(this, n"HandlePlayerStartClosingDoor");
	}

	UFUNCTION()
	bool CanPlayerInteract(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		return HasCharacterMicrphoneChaseComponent(PlayerCharacter);
	}

	UFUNCTION()
	void HandlePlayerStartClosingDoor(UInteractionComponent InteractionComponent, AHazePlayerCharacter PlayerCharacter)
	{
		SetMicrophoneChaseDoor(PlayerCharacter, this);
		InteractionComponent.Disable(n"ActorPickedUp");
	}

	UFUNCTION()
	void AttachPlayerToHandle(AHazePlayerCharacter Player)
	{
		SetMicrophoneChaseDoor(Player, this);
		HazeAkComp.HazePostEvent(StartInteractEvent);
	}

	void AddProgress(float Progress)
	{
		SyncedProgress.Value = FMath::Min(SyncedProgress.Value + Progress, 1.0f);
		HazeAkComp.HazePostEvent(MoveDoorEvent);
	}

	FVector GetTargetLocation() const property
	{
		return ActorTransform.InverseTransformPosition(ActorLocation + ((bIsMirrored ? -ActorForwardVector : ActorForwardVector) * (RelativeLocationOffset * SyncedProgress.Value)));
	}

	UFUNCTION(BlueprintCallable)
	void ReleasePlayer()
	{
		bReleasePlayer = true;
		HazeAkComp.HazePostEvent(StopInteractEvent);
		SetActorTickEnabled(false);
	}
}
