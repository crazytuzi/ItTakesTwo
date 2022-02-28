class AClassicGlowingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshDoor;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FinishedEffectLocation;

	UPROPERTY()
	UNiagaraSystem FinishedEffect;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartGlowAudioEvent;

	UPROPERTY()
	float LerpSpeedMultiplier = 0.65;
	float GlowValue = 0;
	bool bStartGlow = false;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStartGlow)
		{
			GlowValue = FMath::FInterpConstantTo(GlowValue, 1, DeltaSeconds, (1 * LerpSpeedMultiplier) * 0.5f);
			MeshDoor.SetScalarParameterValueOnMaterials(n"Glow", GlowValue);
			
			if(GlowValue >= 0.999)
			{
				System::SetTimer(this, n"PlayFinishedEffect", 0.03f, false);
				bStartGlow = false;
			}
		}
	}

	UFUNCTION()
	void StartGlow()
	{
		GlowValue = 0;
		bStartGlow = true;	
		UHazeAkComponent::HazePostEventFireForget(StartGlowAudioEvent, this.GetActorTransform());

	}

	UFUNCTION()
	void CompleteGlowInstantly()
	{
		MeshDoor.SetScalarParameterValueOnMaterials(n"Glow", 1);
	}

	UFUNCTION()
	void PlayFinishedEffect()
	{
		Niagara::SpawnSystemAtLocation(FinishedEffect, FinishedEffectLocation.GetWorldLocation(), FinishedEffectLocation.GetWorldRotation());
	}
}

