import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Clockwork.TimeBomb.BombMesh;
import Vino.PlayerHealth.PlayerHealthStatics;

enum ESpiderTagPlayerState
{
	Default,
	MovementBlocked,
	InPlay,
	Exploding
};

event void FTagPlayerAnnounceWinner(AHazePlayerCharacter Player);
event void FTagPlayerExploded(AHazePlayerCharacter Player);

class USpiderTagPlayerComp : UActorComponent
{
	ESpiderTagPlayerState SpiderTagPlayerState;

	FTagPlayerAnnounceWinner OnTagPlayerAnnounceWinnerEvent;
	FTagPlayerExploded OnTagPlayerExplodedEvent;

	AHazeCameraActor MainCamera;

	USpiderTagPlayerComp OtherPlayersComp;

	UPROPERTY()
	TSubclassOf<ABombMesh> BombMeshClass;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;
	
	ABombMesh BombMesh;

	float TimeAsIt;
	float MaxItTime = 15.f;

	bool bWeAreIt;

	bool bMovementBlocked;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt DashPrompt;
	default DashPrompt.Action = ActionNames::MovementDash;
    default DashPrompt.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt RightTriggerPrompt;
	default RightTriggerPrompt.Action = ActionNames::PrimaryLevelAbility;
    default RightTriggerPrompt.MaximumDuration = -1.f;

	UPROPERTY(Category = "Temporary")
	TSubclassOf<AActor> TempItRepresentationClass;

	AActor ClassItRepresentation;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}
	
	UFUNCTION()
	void ShowDashPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, DashPrompt, this);
	}

	UFUNCTION()
	void ShowRightTriggerPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, RightTriggerPrompt, this);
	}

	UFUNCTION()
	void HideAllPrompts(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	// int CountDownStage;

	// int MaxCountDownStage = 4;
	// // bool bIsRegenerating;

	float LightRate = 0.8f;

	// float MaxLightRate = 0.83f;

	// UFUNCTION()
	// void CountDownSetter()
	// {
	// 	switch(CountDownStage)
	// 	{
	// 		case 3:
	// 			LightRate = 0.65f;
	// 		break;
			
	// 		case 2:
	// 			LightRate = 0.4f;
	// 		break;

	// 		case 1:
	// 			LightRate = 0.2f;
	// 		break;

	// 		case 0:
	// 			LightRate = 0.1f;
	// 		break;
	// 	}
	// }
}