import Vino.Camera.Components.CameraShotTimedSequenceComponent;
import Peanuts.Triggers.PlayerTrigger;

class ACameraShotTimedSequenceTrigger : APlayerTrigger
{
	UPROPERTY()
	TArray<FCameraShot> CameraShotSequence;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredTrigger");
		Super::BeginPlay();
	}

	UFUNCTION()
	void OnPlayerEnteredTrigger(AHazePlayerCharacter PlayerCharacter)
	{
		UCameraShotTimedSequenceComponent CameraShotSequenceComponent = UCameraShotTimedSequenceComponent::GetOrCreate(PlayerCharacter);
		CameraShotSequenceComponent.Initialize(CameraShotSequence);
		CameraShotSequenceComponent.Play();
	}
}