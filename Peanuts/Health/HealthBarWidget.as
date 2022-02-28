enum EHealthBarSize
{
	Normal,
	Small,
	Big,
}

class UHealthBarWidget : UHazeUserWidget
{
	UPROPERTY(Category = "HealthBar")
	float Health = 1.f;

	UPROPERTY(Category = "HealthBar")
	float MaxHealth = 1.f;

	UPROPERTY(Category = "HealthBar")
	float RecentHealth = 1.f;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "HealthBar")
	float WobbleDamageThreshold = 0.1f;

	float RecentlyDamagedTimer = 0.f;

	// How long it will take for the recent-damage value to start decreasing
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "HealthBar")
	float RecentDamageLerpDelay = 0.5f;

	// How fast the recent damage lerps away after the delay
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "HealthBar")
	float RecentDamageLerpSpeed = 8.f;

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void InitHealthBar(float InMaxHealth)
	{
		MaxHealth = Health = InMaxHealth;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry& MyGeometry, float DeltaTime)
	{
		if (RecentHealth < Health)
		{
			RecentHealth = Health;
		}
		else
		{
			RecentlyDamagedTimer -= DeltaTime;
			if (RecentlyDamagedTimer < 0.f)
				RecentHealth = FMath::Lerp(RecentHealth, Health, RecentDamageLerpSpeed * DeltaTime);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SnapHealthTo(float NewHealth)
	{
		Health = FMath::Clamp(NewHealth, 0, MaxHealth);
		RecentHealth = Health;
		RecentlyDamagedTimer = 0.f;
	}

	UFUNCTION(BlueprintCallable)
	void SetHealthAsDamage(float NewHealth)
	{
		if (FMath::IsNearlyEqual(NewHealth, Health))
			return;

		Health = FMath::Clamp(NewHealth, 0, MaxHealth);
		RecentlyDamagedTimer = RecentDamageLerpDelay;

		// So 20% of health-delta in one burst is considered maximum wobbling
		float WolleyDamagePercent = (RecentHealth - Health) / MaxHealth;
		float Wobble = WolleyDamagePercent / WobbleDamageThreshold;
		OnAddBarWobble(Wobble);
	}

	UFUNCTION(BlueprintCallable)
	void TakeDamage(float Damage)
	{
		SetHealthAsDamage(Health - Damage);
	}

	UFUNCTION(BlueprintEvent)
	void OnAddBarWobble(float Magnitude)
	{
	}

	// Gets the current health as a percentege of max health
	UFUNCTION(BlueprintPure, Category = "HealthBar")
	float GetHealthPercentage()
	{
		if (MaxHealth <= 0.f)
			return 0.f;

		return Math::Saturate(Health / MaxHealth);
	}

	// Gets the recent damage as a percentege of max health
	UFUNCTION(BlueprintPure, Category = "HealthBar")
	float GetRecentDamagePercentage()
	{
		if (MaxHealth <= 0.f)
			return 0.f;

		return Math::Saturate(RecentHealth / MaxHealth);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void SetScreenSpaceOffset(int Offset) {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void SetBarSize(EHealthBarSize Size) {}
}