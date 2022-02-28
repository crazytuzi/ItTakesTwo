import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Peanuts.Fades.FadeStatics;
import Vino.Checkpoints.Checkpoint;

class UParentBlobHealthComponent : UActorComponent
{
	UPROPERTY()
	UNiagaraSystem KillSystem;

	UPROPERTY()
	UNiagaraSystem RespawnSystem;

	FHazeTimeLike DissolveTimeLike;
	default DissolveTimeLike.Duration = 0.5f;

	AParentBlob ParentBlob;
	ACheckpoint CurrentCheckpoint;

	bool bCurrentlyBeingKilled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ParentBlob = Cast<AParentBlob>(Owner);

		DissolveTimeLike.BindUpdate(this, n"UpdateDissolve");
		DissolveTimeLike.BindFinished(this, n"FinishDissolve");
	}

	void Kill()
	{
		if (bCurrentlyBeingKilled)
			return;

		bCurrentlyBeingKilled = true;
		DissolveTimeLike.PlayFromStart();

		FadeOutFullscreen(1.f);
		System::SetTimer(this, n"Respawn", 1.f, false);

		Niagara::SpawnSystemAttached(KillSystem, ParentBlob.Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	UFUNCTION(NotBlueprintCallable)
	void Respawn()
	{
		if (CurrentCheckpoint != nullptr)
			ParentBlob.TeleportActor(CurrentCheckpoint.ActorLocation, CurrentCheckpoint.ActorRotation);
			
		Niagara::SpawnSystemAttached(RespawnSystem, ParentBlob.Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		ClearFullscreenFades();
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.SnapCameraBehindPlayer();

		System::SetTimer(this, n"Undissolve", 1.f, false);

		bCurrentlyBeingKilled = false;
	}

	UFUNCTION()
	void Undissolve()
	{
		DissolveTimeLike.ReverseFromEnd();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateDissolve(float CurValue)
	{
		ParentBlob.Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", CurValue);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishDissolve()
	{

	}
}

UFUNCTION()
void KillAndRespawnParentBlob()
{
	UParentBlobHealthComponent HealthComp = UParentBlobHealthComponent::Get(GetActiveParentBlobActor());
	HealthComp.Kill();
}

UFUNCTION()
void SetParentBlobCheckpoint(ACheckpoint Checkpoint)
{
	UParentBlobHealthComponent HealthComp = UParentBlobHealthComponent::Get(GetActiveParentBlobActor());
	HealthComp.CurrentCheckpoint = Checkpoint;
}