import Peanuts.Dialogue.DialogueComponent;

class UPlayerDialogueCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Dialogue");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UDialogueWidget Widget;

	UDialogueComponent DialogueComp;

	float CharacterTimer;
	int DialogueStep = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DialogueComp = UDialogueComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DialogueComp.bIsInDialogue)
        	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DialogueComp.bIsInDialogue)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Reset dialogue step
		DialogueStep = 0;
		DialogueComp.OnNextLine.ExecuteIfBound(DialogueStep);

		//Widget stuff
		Widget = Cast<UDialogueWidget>(Player.AddWidget(DialogueComp.WidgetClass));
		Widget.DialogueText = DialogueComp.DialogueText[DialogueStep];

		//Timer reset
		CharacterTimer = 0.f;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget.FadeOutAndDestroy();
		Widget = nullptr;
		DialogueComp.OnFinished.ExecuteIfBound();
		DialogueComp.OnFinished.Clear();
		DialogueComp.OnNextLine.Clear();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CharacterTimer += DeltaTime * 40.f;
		FString CurrentStepStr = DialogueComp.DialogueText[DialogueStep].ToString();
		bool bIsStepFinished = Widget.NumVisibleCharacters >= CurrentStepStr.Len();


		if (WasActionStarted(ActionNames::Cancel))
		{
			DialogueComp.bIsInDialogue = false;
			return;
		}

		if(WasActionStarted(ActionNames::MovementJump))
		{
			Widget.OnConfirmButtonPressed();

			if(bIsStepFinished)
			{
				if(DialogueStep >= DialogueComp.DialogueText.Num() - 1)
				{
					DialogueComp.bIsInDialogue = false;
					return;
				}

				DialogueStep ++;
				DialogueComp.OnNextLine.ExecuteIfBound(DialogueStep);
				Widget.DialogueText = DialogueComp.DialogueText[DialogueStep];
				CharacterTimer = 0.f;
			}
			else
			{
				CharacterTimer = CurrentStepStr.Len();
			}
		}

		Widget.NumVisibleCharacters = int(CharacterTimer);

	}

}