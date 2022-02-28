import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;

struct FMoleStealthPlayerIncreaseData
{
	UPROPERTY(BlueprintReadOnly)
	bool bHasIncreased = false;

	UPROPERTY(BlueprintReadOnly)
	float IncreaseAmount = 0;
}

UFUNCTION(BlueprintPure, Category = "Mole Stealth")
FMoleStealthPlayerIncreaseData PlayerIsIncreasingMoleStealthSound(AHazePlayerCharacter Player)
{
	FMoleStealthPlayerIncreaseData Out;
	if(Player == nullptr)
		return Out;

	auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
	if(ManagerComponent == nullptr)
		return Out;

	if(ManagerComponent.CurrentManager == nullptr)
		return Out;

	Out.IncreaseAmount = ManagerComponent.CurrentManager.LastIncreaseAmount[Player.Player];	
	Out.bHasIncreased = Out.IncreaseAmount > 0;
	return Out;
}

UFUNCTION(Category = "Mole Stealth")
void MoleStealthMakeWidgetHidden()
{
	auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
	if(ManagerComponent == nullptr)
		return;

	ManagerComponent.WidgetVisiblityChangeStatus = -1;
	ManagerComponent.UpdateWidgetVisibilityChange();
}

UFUNCTION(Category = "Mole Stealth")
void MoleStealthMakeWidgetVisible(float Delay = 0)
{
	auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
	if(ManagerComponent == nullptr)
		return;

	ManagerComponent.WidgetVisiblityChangeStatus = 1;
	ManagerComponent.ShowWidgetDelay = Delay;
	ManagerComponent.UpdateWidgetVisibilityChange();
}

UFUNCTION(BlueprintPure, Category = "Mole Stealth")
AHazePlayerCharacter GetLastPlayerIncreasedSound()
{
	auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
	if(ManagerComponent == nullptr)
		return nullptr;

	if(ManagerComponent.LastPlayerIncreasedSound == EHazePlayer::MAX)
		return nullptr;
	
	return Game::GetPlayer(ManagerComponent.LastPlayerIncreasedSound);
}