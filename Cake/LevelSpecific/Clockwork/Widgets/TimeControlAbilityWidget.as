import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;

class UTimeControlAbilityWidget : UHazeUserWidget
{
	UPROPERTY()
	float CurrentArrowValue;

	UPROPERTY()
	bool bUsingControlAbility;

	UFUNCTION(BlueprintEvent)
	void SetTimeWidgetVisible(bool bVisible)
	{
	}

	UFUNCTION(BlueprintEvent)
	void ActivatedTimeControlAbility(FVector WidgetLocation)
	{
		bUsingControlAbility = true;
	}
}

class UTimeControlActivationPointWidget : UHazeActivationPointWidget
{
	
}