class ACastleChargerRockfall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDecalComponent Decal;

	UMaterialInstanceDynamic MaterialInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MaterialInstance = Decal.CreateDynamicMaterialInstance();
		UpdateDecal();
	}

	void UpdateDecal(float Progress = 0.f)
	{
		float OuterOpacity = FMath::Clamp(Progress * 5.f, 0.f, 0.60f);
		float MiddleOpacity = FMath::Clamp(Progress * 0.25f, 0.15f, 0.25f);
		// float Time = FMath::Clamp(Progress * 1.5f, 0.f, 1.f);
		// float DangerClose = 0.f;
		// DangerClose = FMath::Clamp((ProgressPercentage - 0.75f) / 0.25f, 0.f, 1.f);
		// DangerClose = ProgressPercentage >= 0.75 ? 1.f : 0.f;

		MaterialInstance.SetScalarParameterValue(n"OuterOpacity", OuterOpacity);
		MaterialInstance.SetScalarParameterValue(n"MiddleSize", Progress);
		MaterialInstance.SetScalarParameterValue(n"MiddleOpacity", MiddleOpacity);
		//MaterialInstance.SetScalarParameterValue(n"DangerClose", DangerClose);
	}
}