class UCastlePlayerAbilitySlotWidget : UHazeUserWidget
{
	UPROPERTY()
	float CooldownDuration = 2.f;
	UPROPERTY()
	float CooldownCurrent = 0.f;	

	// Called when the ability activates
	UFUNCTION(BlueprintEvent)
	void SlotActivated()
	{
		
	}

	// Called whenever the player attempts to press the button ( even when its on cooldown)
	UFUNCTION(BlueprintEvent)
	void SlotPressed()
	{
		
	}
}

class UCastleAbilitySlotData : UDataAsset
{
	UPROPERTY()
	TArray<FCastlePlayerAbilitySlotData> AbilitySlotData;
}

struct FCastlePlayerAbilitySlotData
{
	UPROPERTY()
	FName Name;
	UPROPERTY()
	UTexture2D Icon;
	UPROPERTY()
	FName BindingName = n"InteractionTrigger";
}