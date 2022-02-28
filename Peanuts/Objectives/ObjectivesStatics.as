import Peanuts.Objectives.ObjectivesData;
import Peanuts.Objectives.ObjectivesComponent;

/* Show a specific objective on a player. */
UFUNCTION(Category = "Objectives")
void ShowObjective(AHazePlayerCharacter Player, UObject Instigator, FObjectiveData Objective)
{
	auto ObjectivesComp = UObjectivesComponent::Get(Player);
	ObjectivesComp.Add(Instigator, Objective);
}

/* Complete or remove all objectives added by a specified instigator. */
UFUNCTION(Category = "Objectives")
void RemoveObjectivesByInstigator(AHazePlayerCharacter Player, UObject Instigator, EObjectiveStatus Status = EObjectiveStatus::Completed)
{
	auto ObjectivesComp = UObjectivesComponent::Get(Player);
	ObjectivesComp.Remove(Instigator, Status);
}

/* Show a header for objectives that are currently active. */
UFUNCTION(Category = "Objectives")
void ShowObjectivesHeader(AHazePlayerCharacter Player, FText ObjectivesHeader)
{
	auto ObjectivesComp = UObjectivesComponent::Get(Player);
	ObjectivesComp.SetObjectivesHeader(ObjectivesHeader);
}

/* Remove the objectives header that is currently active. */
UFUNCTION(Category = "Objectives")
void RemoveObjectivesHeader(AHazePlayerCharacter Player)
{
	auto ObjectivesComp = UObjectivesComponent::Get(Player);
	ObjectivesComp.SetObjectivesHeader(FText());
}

/* Hide objective HUD based on a specific instigator. */
UFUNCTION(Category = "Objectives")
void BlockObjectivesHUD(AHazePlayerCharacter Player, UObject Instigator)
{
	auto ObjectivesComp = UObjectivesComponent::Get(Player);
	ObjectivesComp.BlockHUD(Instigator);
}

/* Remove the objectives HUD hiding that a specific instigator did. */
UFUNCTION(Category = "Objectives")
void UnblockObjectivesHUD(AHazePlayerCharacter Player, UObject Instigator)
{
	auto ObjectivesComp = UObjectivesComponent::Get(Player);
	ObjectivesComp.UnblockHUD(Instigator);
}