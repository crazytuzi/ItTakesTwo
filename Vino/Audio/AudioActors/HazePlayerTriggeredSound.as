import Peanuts.Triggers.PlayerTrigger;

/**
 * A volume that plays one or more sounds the first time a player
 * enters it. Will not trigger more than once.
 */
class AHazePlayerTriggeredSound : APlayerTrigger
{
	default bTriggerLocally = true;

    default Shape::SetVolumeBrushColor(this, FLinearColor::Blue);

	UPROPERTY(Category = "Triggered Sound")
	UAkAudioEvent PrimaryEvent;

	UPROPERTY(Category = "Triggered Sound")
	TArray<UAkAudioEvent> AdditionalEvents;

	UPROPERTY(Category = "Triggered Sound")
	bool bTriggerMultipleTimes = false;

    void EnterTrigger(AActor Actor) override
	{
		Super::EnterTrigger(Actor);

		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player != nullptr)
		{
			auto AkComponent = UHazeAkComponent::GetOrCreateHazeAkComponent(Player);
			if (PrimaryEvent != nullptr)
				AkComponent.HazePostEvent(PrimaryEvent);
			for (auto ExtraEvent : AdditionalEvents)
			{
				if (ExtraEvent != nullptr)
					AkComponent.HazePostEvent(ExtraEvent);
			}

			if (!bTriggerMultipleTimes)
				SetTriggerEnabled(false);
		}
	}

    void LeaveTrigger(AActor Actor) override
	{
		Super::LeaveTrigger(Actor);
	}
};