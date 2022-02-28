import Peanuts.Health.HealthBarWidget;

class UBossHealthBarWidget : UHealthBarWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HealthBar")
	FText BossName;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HealthBar")
	int NumHealthSegments;

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void InitBossHealthBar(FText InBossName, float InMaxHealth, int InNumSegments = 1)
	{
		InitHealthBar(InMaxHealth);
		BossName = InBossName;
		NumHealthSegments = InNumSegments;
	}
}