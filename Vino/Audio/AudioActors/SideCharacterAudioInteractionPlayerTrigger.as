import Peanuts.Triggers.PlayerTrigger;

enum EInteractionTriggerType
{
	None,
	PlayerEnter,
	BothPlayerEnter
}

class ASideCharacterAudioInteractionPlayerTrigger : APlayerTrigger
{
	default bTriggerLocally = true;
    default Shape::SetVolumeBrushColor(this, FLinearColor::Blue);
	private TArray<UHazeAkComponent> LinkedHazeAkComps;
	private int32 TriggerPlayerCount = 0;

	UPROPERTY(Category = "Characters")
	TArray<AHazeActor> LinkedCharacters;

	UPROPERTY(Category = "Interaction Type")
	EInteractionTriggerType TriggerType = EInteractionTriggerType::PlayerEnter;

	UPROPERTY(Category = "Interaction Type")
	bool bTriggerOnce = false;

	UPROPERTY(Category = "On Enter")
	UAkAudioEvent OnEnterInteractionEvent;

	UPROPERTY(Category = "On Exit")
	UAkAudioEvent OnExitInteractionEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto& Actor : LinkedCharacters)
		{
			if(Actor == nullptr)
				continue;

			UHazeAkComponent LinkedActorComp = UHazeAkComponent::GetOrCreate(Actor);
			LinkedHazeAkComps.AddUnique(LinkedActorComp);
		}

		Super::BeginPlay();
	}

	void EnterTrigger(AActor Actor) override
	{
		Super::EnterTrigger(Actor);

		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player == nullptr)
			return;

		TriggerPlayerCount ++;		
		if(TriggerType == EInteractionTriggerType::BothPlayerEnter && TriggerPlayerCount < 2)
			return;

		// Only post looping events once
		if(OnEnterInteractionEvent.HazeIsInfinite && TriggerPlayerCount > 1)
			return;

		for(auto& LinkedComp : LinkedHazeAkComps)
		{
			LinkedComp.HazePostEvent(OnEnterInteractionEvent);
		}		

		if (bTriggerOnce)
			SetTriggerEnabled(false);		
	}

    void LeaveTrigger(AActor Actor) override
	{
		Super::LeaveTrigger(Actor);

		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player == nullptr)
			return;

		TriggerPlayerCount --;		
		if(TriggerType == EInteractionTriggerType::BothPlayerEnter && TriggerPlayerCount > 0)
			return;

		// Only post exit event on last exit if enter event is looping
		if(OnEnterInteractionEvent.HazeIsInfinite && TriggerPlayerCount > 0)
			return;

		for(auto& LinkedComp : LinkedHazeAkComps)
		{
			if(LinkedComp == nullptr)
				continue;
				
			LinkedComp.HazePostEvent(OnExitInteractionEvent);
		}	
	}
}