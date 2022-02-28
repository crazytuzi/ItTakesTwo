class ASpaceConductorIndicatorStar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent StarRoot;

	UPROPERTY(DefaultComponent, Attach = StarRoot)
	UStaticMeshComponent StarMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 6000.f;

	UPROPERTY()
	bool bReverseRotation = false;

	UPROPERTY()
	bool bStartActive = false;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface LitMaterial;
	UMaterialInterface DefaultMaterial;

	bool bActive = false;

	UPROPERTY()
	float MinRotationRate = 4.f;
	UPROPERTY()
	float MaxRotationRate = 7.f;
	float RotationRate = 0.f;
	float RotationIncreaseSpeed = 2.f;
	float RotationDecreaseSpeed = 5.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultMaterial = StarMesh.GetMaterial(1);

		MaxRotationRate = FMath::RandRange(MinRotationRate, MaxRotationRate);

		if (bStartActive)
		{
			SetActiveStatus(true);
		}
	}

	UFUNCTION()
	void SetActiveStatus(bool bStatus)
	{
		if (bActive != bStatus)
		{
			bActive = bStatus;
			UMaterialInterface Material = bActive ? LitMaterial : DefaultMaterial;
			StarMesh.SetMaterial(1, Material);
			if (bActive)
				SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
			RotationRate += RotationIncreaseSpeed * DeltaTime;
		else
			RotationRate -= RotationDecreaseSpeed * DeltaTime;

		RotationRate = FMath::Clamp(RotationRate, 0.f, MaxRotationRate);
		float RotRate = RotationRate;
		if (bReverseRotation)
			RotRate *= -1;

		StarRoot.AddLocalRotation(FRotator(RotRate, 0.f, 0.f));

		if (RotationRate == 0.f)
			SetActorTickEnabled(false);
	}
}