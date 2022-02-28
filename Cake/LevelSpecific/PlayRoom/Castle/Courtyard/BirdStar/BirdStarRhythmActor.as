import Cake.LevelSpecific.Music.NightClub.RhythmActor;

class ABirdStarRhythmActor : ARhythmActor
{
	default bCheckOverlap = false;
	default PushTempoCooldown = 0.1f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();

		LeftFaceButton.OnTempoHit.AddUFunction(this, n"Handle_LeftFaceButtonHit");
		LeftFaceButton.OnTempoFail.AddUFunction(this, n"Handle_LeftFaceButtonMiss");

		TopFaceButton.OnTempoHit.AddUFunction(this, n"Handle_TopFaceButtonHit");
		TopFaceButton.OnTempoFail.AddUFunction(this, n"Handle_TopFaceButtonMiss");

		RightFaceButton.OnTempoHit.AddUFunction(this, n"Handle_RightFaceButtonHit");
		RightFaceButton.OnTempoFail.AddUFunction(this, n"Handle_RightFaceButtonMiss");

		OnRhythmHitFailed.AddUFunction(this, n"Handle_HitMiss");
	}

	// Select the backdrop that the vfx will attach to, if we don't have this, vfx will not be visible in the scene capture
	UPROPERTY(Category = VFX)
	AActor BackdropActor;

	UPROPERTY(Category = VFX)
	UNiagaraSystem HitVFX;

	UPROPERTY(Category = VFX)
	UNiagaraSystem MissVFX;

	UFUNCTION(NotBlueprintCallable)
	private void Handle_HitMiss(URhythmComponent RhythmComponent)
	{
		SpawnVFXOnComponent(RhythmComponent, MissVFX);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_LeftFaceButtonHit(ARhythmTempoActor TempoActor)
	{
		SpawnVFXOnComponent(LeftFaceButton, HitVFX);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_LeftFaceButtonMiss(ARhythmTempoActor TempoActor)
	{
		SpawnVFXOnComponent(LeftFaceButton, MissVFX);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_TopFaceButtonHit(ARhythmTempoActor TempoActor)
	{
		SpawnVFXOnComponent(TopFaceButton, HitVFX);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_TopFaceButtonMiss(ARhythmTempoActor TempoActor)
	{
		SpawnVFXOnComponent(TopFaceButton, MissVFX);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_RightFaceButtonHit(ARhythmTempoActor TempoActor)
	{
		SpawnVFXOnComponent(RightFaceButton, HitVFX);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_RightFaceButtonMiss(ARhythmTempoActor TempoActor)
	{
		SpawnVFXOnComponent(RightFaceButton, MissVFX);
	}

	private void SpawnVFXOnComponent(USceneComponent SceneComp, UNiagaraSystem NiagaraSystem)
	{
		if(BackdropActor == nullptr)
			return;
		UNiagaraComponent NiagaraComp = Niagara::SpawnSystemAttached(NiagaraSystem, BackdropActor.RootComponent, NAME_None, SceneComp.WorldLocation, FRotator::ZeroRotator, EAttachLocation::KeepWorldPosition, true);
		NiagaraComp.SetWorldScale3D(FVector(1.0f));
	}
}
