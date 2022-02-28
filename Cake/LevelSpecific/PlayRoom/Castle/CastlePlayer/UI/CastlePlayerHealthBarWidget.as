
class UCastlePlayerHealthBarWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float RecentHealth = 0.f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float CurrentHealth = 0.f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsDead = false;

	private float PrevRecentHealth = 0.f;
	private float PrevCurrentHealth = 0.f;
	private bool bPrevIsDead = false;

	void Update()
	{
		bool bUpdated = false;
		if (bIsDead != bPrevIsDead)
		{
			bPrevIsDead = bIsDead;
			bUpdated = true;
		}
		if (CurrentHealth != PrevCurrentHealth)
		{
			PrevCurrentHealth = CurrentHealth;
			bUpdated = true;
		}
		if (RecentHealth != PrevRecentHealth)
		{
			PrevRecentHealth = RecentHealth;
			bUpdated = true;
		}

		if (bUpdated)
			BP_UpdateHealthValues();
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateHealthValues() {}
};