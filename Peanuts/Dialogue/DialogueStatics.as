import Peanuts.Dialogue.DialogueComponent;
import Peanuts.Dialogue.StationaryDialogueComponent;

UFUNCTION(Category = Dialogue)
void StartDialogue(AHazePlayerCharacter Player, TArray<FText> DialogueText, FOnDialogueFinished OnFinished)
{
	auto DialogueComponent = UDialogueComponent::GetOrCreate(Player);
	DialogueComponent.DialogueText = DialogueText;
	DialogueComponent.bIsInDialogue = true;
	DialogueComponent.OnFinished = OnFinished;
	DialogueComponent.OnNextLine.Clear();
}

UFUNCTION(Category = Dialogue)
void StartStationaryDialogue(AHazePlayerCharacter Player, TArray<FText> DialogueText, FOnStationaryDialogueFinished OnFinished, AHazeCameraActor Camera)
{
	auto DialogueComponent = UDialogueComponent::GetOrCreate(Player);
	auto StationaryDialogueComponent = UStationaryDialogueComponent::GetOrCreate(Player);
	DialogueComponent.DialogueText = DialogueText;
	StationaryDialogueComponent.OnFinished = OnFinished;
	StationaryDialogueComponent.bIsInStationaryDialogue = true;
	StationaryDialogueComponent.Camera = Camera;
}
