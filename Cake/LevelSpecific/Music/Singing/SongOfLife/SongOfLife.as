UCLASS(Abstract)
class ASongOfLife : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent NoteComp;

	default SetActorHiddenInGame(true);

	void ActivateSongOfLife()
	{
		SetActorHiddenInGame(false);
	}

	void DeactivateSongOfLife()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetActorRotation(FRotator::ZeroRotator);
	}
}