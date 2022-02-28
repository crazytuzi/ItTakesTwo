class UPlayerStanceComponent : UActorComponent
{
	UPROPERTY()
	bool bUseAlertedStance = false;
}

UFUNCTION()
void EnableAlertedStance(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;

	UPlayerStanceComponent StanceComp = UPlayerStanceComponent::GetOrCreate(Player);	
	StanceComp.bUseAlertedStance = true;
}

UFUNCTION()
void DisableAlertedStance(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;

	UPlayerStanceComponent StanceComp = UPlayerStanceComponent::GetOrCreate(Player);	
	StanceComp.bUseAlertedStance = false;
}