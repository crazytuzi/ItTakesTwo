class USpaceStationLevelVisibilityComponent : UActorComponent
{
	bool bPlayerIsolated = false;

	UFUNCTION()
	void ShowDefaultLevels(AHazePlayerCharacter Player)
	{
		BP_ShowDefaultLevels(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowDefaultLevels(AHazePlayerCharacter Player) {}
	
	UFUNCTION()
	void HideDefaultLevels(AHazePlayerCharacter Player)
	{
		BP_HideDefaultLevels(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_HideDefaultLevels(AHazePlayerCharacter Player) {}

	UFUNCTION()
	void HideNonDefaultLevels(AHazePlayerCharacter Player)
	{
		BP_HideNonDefaultLevels(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_HideNonDefaultLevels(AHazePlayerCharacter Player) {}

	UFUNCTION()
	void ShowPreviousLevels(AHazePlayerCharacter Player)
	{
		BP_ShowPreviousLevels(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowPreviousLevels(AHazePlayerCharacter Player) {}
}

UFUNCTION()
void ShowSpaceStationDefaultLevels(AHazePlayerCharacter Player)
{
	USpaceStationLevelVisibilityComponent Comp = USpaceStationLevelVisibilityComponent::Get(Player);
	Comp.ShowDefaultLevels(Player);
}

UFUNCTION()
void HideSpaceStationDefaultLevels(AHazePlayerCharacter Player)
{
	USpaceStationLevelVisibilityComponent Comp = USpaceStationLevelVisibilityComponent::Get(Player);
	Comp.HideDefaultLevels(Player);
}

UFUNCTION()
void HideSpaceStationNonDefaultLevels(AHazePlayerCharacter Player)
{
	USpaceStationLevelVisibilityComponent Comp = USpaceStationLevelVisibilityComponent::Get(Player);
	Comp.HideNonDefaultLevels(Player);
}

UFUNCTION()
void ShowSpaceStationPreviousLevels(AHazePlayerCharacter Player)
{
	USpaceStationLevelVisibilityComponent Comp = USpaceStationLevelVisibilityComponent::Get(Player);
	Comp.ShowPreviousLevels(Player);
}