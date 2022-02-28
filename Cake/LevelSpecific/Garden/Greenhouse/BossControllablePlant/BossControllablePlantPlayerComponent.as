class UBossControllablePlantPlayerComponent : UActorComponent
{
	bool LeftTrigger;
	bool RightTrigger;

	FVector2D LeftStickInput;
	FVector2D RightStickInput;

	bool bInSoil = false;

	UFUNCTION()
	void UpdatePlayerTriggersInput(bool ActioningLeftTrigger, bool ActioningRightTrigger)
	{
		LeftTrigger = ActioningLeftTrigger;
		RightTrigger = ActioningRightTrigger;
	}

	UFUNCTION()
	void UpdatePlayerLeftStickInput(FVector2D PlayerStickInput)
	{
		LeftStickInput = PlayerStickInput;
	}

	UFUNCTION()
	void UpdatePlayerRightStickInput(FVector2D PlayerStickInput)
	{
		RightStickInput = PlayerStickInput;
	}
}
