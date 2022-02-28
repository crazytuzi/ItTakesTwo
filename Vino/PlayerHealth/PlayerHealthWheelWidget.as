
class UPlayerHealthWheelWidget : UHazeUserWidget
{
	// Fraction of health below which to permanently display damaged state
	UPROPERTY()
	float CriticalHealthPercentage = 0.15f;

	// How long after damage is over to display damaged status
	UPROPERTY()
	float DamagedLingerTimeSeconds = 1.f;

	// How fast the healing state lerps in and out
	UPROPERTY()
	float HealingStateLerpSpeed = 7.f;

	UPROPERTY(NotEditable)
	int HealthChunks = 3;

	UPROPERTY(NotEditable)
	float TotalHealth = 1.f;

	UPROPERTY(NotEditable)
	float HealedHealth = 0.f;

	UPROPERTY(NotEditable)
	float RegeneratedHealth = 0.f;

	UPROPERTY(NotEditable)
	float DamagedHealth = 0.f;

	private UMaterialInstanceDynamic DynamicMaterial;

	private float DisplayCurrentHealth = 0.f;
	private float DisplayTargetHealth = 0.f;
	private float DisplayDamaged = 0.f;
	private float DisplayHealing = 0.f;

	private bool bIsRegenerating = false;

	UFUNCTION(BlueprintEvent)
	void OnMaterialChanged(UMaterialInterface Material) {}

	UFUNCTION()
	void SetBaseMaterial(UMaterialInterface Material)
	{
		DynamicMaterial = Material::CreateDynamicMaterialInstance(Material);
		OnMaterialChanged(DynamicMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		float NewCurrentHealth = TotalHealth + DamagedHealth - RegeneratedHealth;
		if (NewCurrentHealth != DisplayCurrentHealth)
		{
			DynamicMaterial.SetScalarParameterValue(n"CurrentHealth", NewCurrentHealth);
			DisplayCurrentHealth = NewCurrentHealth;
		}

		float NewTargetHealth = TotalHealth - RegeneratedHealth;
		if (NewTargetHealth != DisplayTargetHealth)
		{
			DynamicMaterial.SetScalarParameterValue(n"TargetHealth", NewTargetHealth);
			DisplayTargetHealth = NewTargetHealth;
		}

		bool bShowDamaged = (TotalHealth < CriticalHealthPercentage) || (DamagedHealth > 0.f);
		float NewDamaged = 0.f;
		if (bShowDamaged)
			NewDamaged = 1.f;
		else
			NewDamaged = FMath::FInterpConstantTo(DisplayDamaged, 0.f, DeltaTime, 1.f / DamagedLingerTimeSeconds);

		if (NewDamaged != DisplayDamaged)
		{
			DynamicMaterial.SetScalarParameterValue(n"Damaged", NewDamaged);
			DisplayDamaged = NewDamaged;
		}

		if (RegeneratedHealth > 0.f || HealedHealth > 0.f)
		{
			if (DisplayHealing < 1.f)
			{
				DisplayHealing = FMath::FInterpConstantTo(DisplayHealing, 1.f, DeltaTime, HealingStateLerpSpeed);
				DynamicMaterial.SetScalarParameterValue(n"IsHealing", DisplayHealing);
			}
		}
		else
		{
			if (DisplayHealing > 0.f)
			{
				DisplayHealing = FMath::FInterpConstantTo(DisplayHealing, 0.f, DeltaTime, HealingStateLerpSpeed);
				DynamicMaterial.SetScalarParameterValue(n"IsHealing", DisplayHealing);
			}
		}
	}
};