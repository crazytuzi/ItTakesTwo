class USnowballFightCrosshairWidget : UHazeUserWidget
{
	UPROPERTY()
	FVector2D AimScreenPosition = FVector2D(0.5f, 0.5f);

	UPROPERTY()
	bool HasAimTarget = false;


	UFUNCTION(BlueprintEvent)
	void Pulse()
	{

	}

	UFUNCTION(BlueprintEvent)
	void UpdateAmmo(int CurrentAmmo, bool NoAnimation)
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void PlayNoAmmoWobble()
	{

	}
};