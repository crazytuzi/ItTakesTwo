class UPirateMinePulsatingEffectComponent : USceneComponent
{
	USkeletalMeshComponent SkelMeshRef;
	FLinearColor OriginalEmissive;
	FLinearColor CurrentEmissive;

	float Alpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeactivatePulsatingEffect();
	}

	UFUNCTION(BlueprintCallable)
	void SetPulsatingSkeletalMesh(USkeletalMeshComponent SkelMesh)
	{
		SkelMeshRef = SkelMesh;

		UMaterialInstanceDynamic DynamicMaterial = SkelMeshRef.CreateDynamicMaterialInstance(0);
		OriginalEmissive = DynamicMaterial.GetVectorParameterValue(n"Emissive Tint");
	}	

	UFUNCTION(BlueprintCallable)
	void DeactivatePulsatingEffect()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void ActivatePulsatingEffect()
	{
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float SinTime = FMath::Abs(FMath::Sin(Time::GetGameTimeSeconds() * 1.35f));

		CurrentEmissive = FMath::Lerp(OriginalEmissive, FLinearColor(0, 0, 0, 0), SinTime);

		SkelMeshRef.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", CurrentEmissive);
	}


}
