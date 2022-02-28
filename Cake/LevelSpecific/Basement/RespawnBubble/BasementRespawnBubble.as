import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Basement.BasementBoss.LightBubbleCapability;

class ABasementRespawnBubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DeathSystem;

	bool bActive = false;

	AParentBlob ParentBlob;

	UPROPERTY()
	ACheckpoint TargetCheckpoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION()
	void Activate()
	{
		if (bActive)
			return;
			
		if (ParentBlob == nullptr)
			ParentBlob = GetActiveParentBlobActor();

		if (ParentBlob.IsAnyCapabilityActive(ULightBubbleCapability::StaticClass()))
			return;

		bActive = true;

		GetActiveParentBlobActor().Mesh.SetHiddenInGame(true);
		Niagara::SpawnSystemAttached(DeathSystem, GetActiveParentBlobActor().Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		System::SetTimer(this, n"TeleportPlayers", 0.5f, false);
	}

	UFUNCTION()
	void TeleportPlayers()
	{
		GetActiveParentBlobActor().TeleportActor(TargetCheckpoint.ActorLocation, TargetCheckpoint.ActorRotation);
		bActive = false;
		GetActiveParentBlobActor().Mesh.SetHiddenInGame(false);
	}

	UFUNCTION()
	void UpdateTargetCheckpoint(ACheckpoint Checkpoint)
	{
		TargetCheckpoint = Checkpoint;
	}
}