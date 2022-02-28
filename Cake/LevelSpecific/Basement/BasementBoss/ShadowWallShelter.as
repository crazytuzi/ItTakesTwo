import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

event void FShadowWallShelterEvent();

UCLASS(Abstract)
class AShadowWallShelter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShelterRoot;

	UPROPERTY(DefaultComponent, Attach = ShelterRoot)
	UStaticMeshComponent ShelterBaseMesh;

	UPROPERTY(DefaultComponent, Attach = ShelterRoot)
	UStaticMeshComponent ShelterAuraMesh;

	UPROPERTY(DefaultComponent, Attach = ShelterRoot)
	USpotLightComponent SpotLightComp;

	UPROPERTY(DefaultComponent, Attach = ShelterRoot)
	UBoxComponent PlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = ShelterRoot)
	UNiagaraComponent FallEffectComp;
	default FallEffectComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = ShelterRoot)
	UNiagaraComponent GlowEffectComp;
	default GlowEffectComp.bAutoActivate = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FallTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FadeTimelike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SinkTimeLike;

	UPROPERTY()
	FShadowWallShelterEvent OnShelterEnter;

	UPROPERTY()
	FShadowWallShelterEvent OnShelterExit;

	UPROPERTY()
	float FallDelay = 0.f;

	UPROPERTY()
	TArray<AShadowWallShelter> NextShelters;

	UMaterialInstanceDynamic AuraMaterialInstance;

	bool bPlayersInShelter = false;
	bool bSafeZoneActive = false;

	float StartHeight = 3000.f;
	float LightIntensity = 500.f;

	FTimerHandle StartFallingTimerHandle;

	float CurrentOpacity = 0.f;
	float CurrentAuraHeight = 0.25f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		FallTimeLike.SetPlayRate(0.5f);
		FallTimeLike.BindUpdate(this, n"UpdateFall");
		FallTimeLike.BindFinished(this, n"FinishFall");

		FadeTimelike.SetPlayRate(0.7f);
		FadeTimelike.BindUpdate(this, n"UpdateFade");
		FadeTimelike.BindFinished(this, n"FinishFade");

		SinkTimeLike.BindUpdate(this, n"UpdateSink");
		SinkTimeLike.BindFinished(this, n"FinishSink");

		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		PlayerTrigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");

		AuraMaterialInstance = Material::CreateDynamicMaterialInstance(ShelterAuraMesh.GetMaterial(0));
		ShelterAuraMesh.SetMaterial(0, AuraMaterialInstance);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (!bSafeZoneActive)
			return;

		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		bPlayersInShelter = true;
		ParentBlob.SetCapabilityActionState(n"LightBubble", EHazeActionState::Active);
		OnShelterEnter.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (!bPlayersInShelter)
			return;

		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		LeaveShelter();
    }

	void LeaveShelter()
	{
		bPlayersInShelter = false;
		GetActiveParentBlobActor().SetCapabilityActionState(n"LightBubble", EHazeActionState::Inactive);
		OnShelterExit.Broadcast();
	}

	UFUNCTION()
	void StartFalling()
	{
		if (FallDelay == 0.f)
			TriggerFall();
		else
			StartFallingTimerHandle = System::SetTimer(this, n"TriggerFall", FallDelay, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerFall()
	{
		FVector Loc = FVector(FMath::Sin(0.f * 4.f) * 2000.f, FMath::Sin((0.f + 0.5f) * 3.f) * 2000.f, StartHeight);
		ShelterRoot.SetRelativeLocation(Loc);
		FallTimeLike.PlayFromStart();
		SetActorHiddenInGame(false);
		ShelterAuraMesh.SetRelativeScale3D(FVector(1.f, 1.f, 0.25f));
		FallEffectComp.Activate(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateFall(float CurValue)
	{
		FVector Loc = FVector(FMath::Sin(CurValue * 4.f) * 2000.f, FMath::Sin((CurValue + 0.5f) * 3.f) * 2000.f, StartHeight);
		FVector CurLoc = FMath::Lerp(Loc, FVector::ZeroVector, CurValue);

		FRotator Rot = FRotator(FMath::Sin((CurValue + 0.5f) * 3.f) * 70.f, 0.f, FMath::Sin(CurValue * 4.f * 70.f));
		FQuat CurRot = FQuat::FastLerp(FQuat(Rot), FQuat(FRotator(0.f, 360.f, 0.f)), CurValue);

		ShelterRoot.SetRelativeLocationAndRotation(CurLoc, CurRot);

		float Opacity = Math::Saturate(CurValue - 0.95f) * 20.f;
		AuraMaterialInstance.SetScalarParameterValue(n"Opacity", Opacity * 0.25f);
		SpotLightComp.SetIntensity(Opacity * 500.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishFall()
	{
		GlowEffectComp.Activate(true);
		FallEffectComp.Deactivate();
		bSafeZoneActive = true;
		CurrentOpacity = 0.25f;
		CurrentAuraHeight = 0.25f;
		// FadeTimelike.PlayFromStart();
	}

	void StartFading()
	{
		// FadeTimelike.PlayFromStart();
	}

	UFUNCTION()
	void ShelterHitByAttack()
	{
		bSafeZoneActive = false;
		SinkTimeLike.PlayFromStart();
		GlowEffectComp.Deactivate();

		if (bPlayersInShelter)
			LeaveShelter();

		for (AShadowWallShelter Shelter : NextShelters)
		{
			Shelter.StartFalling();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateFade(float CurValue)
	{
		AuraMaterialInstance.SetScalarParameterValue(n"Opacity", CurValue);
		SpotLightComp.SetIntensity(CurValue * LightIntensity);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishFade()
	{
		bSafeZoneActive = false;
		SinkTimeLike.PlayFromStart();

		if (bPlayersInShelter)
			LeaveShelter();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateSink(float CurValue)
	{
		float CurHeight = FMath::Lerp(0.f, -50.f, CurValue);
		ShelterRoot.SetRelativeLocation(FVector(0.f, 0.f, CurHeight));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishSink()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void DestroyShelter()
	{
		System::ClearAndInvalidateTimerHandle(StartFallingTimerHandle);

		FallTimeLike.Stop();
		FadeTimelike.Stop();
		SinkTimeLike.Stop();

		bSafeZoneActive = false;
		bPlayersInShelter = false;

		AuraMaterialInstance.SetScalarParameterValue(n"Opacity", 0.f);

		GlowEffectComp.Deactivate();

		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (FallTimeLike.IsPlaying())
			return;

		if (bPlayersInShelter)
		{
			CurrentOpacity = FMath::FInterpTo(CurrentOpacity, 1.f, DeltaTime, 3.f);
			CurrentAuraHeight = FMath::FInterpTo(CurrentAuraHeight, 0.75f, DeltaTime, 3.f);
		}
		else
		{
			CurrentOpacity = FMath::FInterpTo(CurrentOpacity, 0.1f, DeltaTime, 3.f);
			CurrentAuraHeight = FMath::FInterpTo(CurrentAuraHeight, 0.25f, DeltaTime, 3.f);
		}

		
		AuraMaterialInstance.SetScalarParameterValue(n"Opacity", CurrentOpacity);
		ShelterAuraMesh.SetRelativeScale3D(FVector(1.f, 1.f, CurrentAuraHeight));
		ShelterBaseMesh.SetScalarParameterValueOnMaterialIndex(1, n"EmissiveScale", CurrentOpacity);
	}
}