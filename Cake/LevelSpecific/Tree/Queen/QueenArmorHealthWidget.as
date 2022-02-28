
class UQueenArmorHealthWidget : UHazeUserWidget
{
	UPROPERTY()
	float HealthPercentage;

	UPROPERTY()
	bool bIsObscured;

	UPROPERTY()
	bool bShouldHide;

	UFUNCTION()
	void TakeDamage(float Damage)
	{

	}
}