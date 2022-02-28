import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.UI.CastlePlayerAbilitySlotWidget;

class UCastlePlayerAbilityBarWidget : UHazeUserWidget
{
	UPROPERTY()
	TMap<FName, UCastlePlayerAbilitySlotWidget> NameToSlot;
	UPROPERTY()
	UCastleAbilitySlotData AbilityData;

	UPROPERTY()
	float UltimateProgress = 0.f;
	UPROPERTY()
	bool bIsUsingUltimate = false;

	UFUNCTION()
	UCastlePlayerAbilitySlotWidget GetWidgetForSlot(FName SlotName)
	{		
		// HI TOM
		UCastlePlayerAbilitySlotWidget WidgeSlot;
		
		ensure(NameToSlot.Find(SlotName, WidgeSlot));
		
		return WidgeSlot;
	}

	UFUNCTION(BlueprintEvent)
	void UpdateAbilityData(UCastleAbilitySlotData AbilityData)
	{
	}
}
