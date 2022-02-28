class AMicrophoneChaseCrushBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh02;

	UPROPERTY()
	float LerpDuration = 1.f;

	bool bShouldLerp = false;

	float CurrentLerpValue = 0.f;

	float TargetParamValue = 0.f;
	float CurrentParamValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentParamValue = FMath::FInterpTo(CurrentParamValue, TargetParamValue, DeltaTime, 8.f);

		Mesh01.SetScalarParameterValueOnMaterialIndex(0, n"BlendValue", CurrentParamValue);
		Mesh02.SetScalarParameterValueOnMaterialIndex(0, n"BlendValue", CurrentParamValue);

		if (!bShouldLerp)
			return;

		CurrentLerpValue += DeltaTime / LerpDuration;

		if (CurrentLerpValue >= 1.f)
		{
			CurrentLerpValue = 1.f;
			bShouldLerp = false;
		}
		
		Mesh01.SetScalarParameterValueOnMaterialIndex(0, n"BlendValue", CurrentLerpValue);
		Mesh02.SetScalarParameterValueOnMaterialIndex(0, n"BlendValue", CurrentLerpValue);
	}

	UFUNCTION()
	void StartCrushingBeam()
	{
		bShouldLerp = true;
	}

	UFUNCTION()
	void SetCrushParam(float NewCrushParamValue)
	{
		TargetParamValue = NewCrushParamValue;
		// Mesh01.SetScalarParameterValueOnMaterialIndex(0, n"BlendValue", NewCrushParamValue);
		// Mesh02.SetScalarParameterValueOnMaterialIndex(0, n"BlendValue", NewCrushParamValue);
	}
}