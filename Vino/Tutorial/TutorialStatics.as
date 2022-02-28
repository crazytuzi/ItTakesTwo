import Vino.Tutorial.TutorialCapability;
import Vino.Tutorial.TutorialComponent;
import Vino.Tutorial.CancelPromptWidget;

/**
 * Add a new single tutorial prompt to the screen.
 */
UFUNCTION(Category = "Tutorials", Meta = (AutoSplit = "Prompt", ExpandToEnum = "Prompt_Action", ExpandedEnum = "/Script/Angelscript.ActionNames"))
void ShowTutorialPrompt(AHazePlayerCharacter Player, FTutorialPrompt Prompt, UObject Instigator)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	if (Prompt.Text.IsInitializedFromString())
	{
		PrintScaled(
			"Tutorial prompt trying to show text '"+Prompt.Text+"' was initialized using FText::FromString"
			+"\nThis breaks translation, so please use NSLOCTEXT or put it in a UPROPERTY() instead!",
		30.f, FLinearColor(1.f, 0.5f, 0.f), 2.f);
		ensure(false);
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddTutorial(Prompt, Instigator);
}

/**
 * Add a new chain of tutorial prompts to the screen.
 *  NOTE: Prompt chains IGNORE any MaximumDuration or RemoveWhenPressed Mode values specified
 *  in any of the prompts in the chain.
 */
UFUNCTION(Category = "Tutorials")
void ShowTutorialPromptChain(AHazePlayerCharacter Player, FTutorialPromptChain PromptChain, UObject Instigator, int InitialPosition)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	for (auto& Prompt : PromptChain.Prompts)
	{
		if (Prompt.Text.IsInitializedFromString())
		{
			PrintScaled(
				"Tutorial prompt trying to show text '"+Prompt.Text+"' was initialized using FText::FromString"
				+"\nThis breaks translation, so please use NSLOCTEXT or put it in a UPROPERTY() instead!",
			30.f, FLinearColor(1.f, 0.5f, 0.f), 2.f);
			ensure(false);
		}
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddTutorialChain(PromptChain, Instigator, InitialPosition);
}

/**
 * Set which position in the prompt chain is currently active for the
 * tutorial chain added with the specified instigator.
 */
UFUNCTION(Category = "Tutorials")
void SetTutorialPromptChainPosition(AHazePlayerCharacter Player, UObject Instigator, int ChainPosition)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.SetChainPosition(Instigator, ChainPosition);
}

/**
 * Add a tutorial prompt in world space that hovers over an object.
 * If no attach component is specified, the player mesh is used.
 * Only one tutorial can be attached to the same component at a time. Additional prompts
 * are not displayed until the previous one is removed.
 * TutorialPromptMode (RemoveWhenPressed), and MaximumDuration are ignored for world prompts, they always need
 * to be manually removed via RemoveTutorialPromptByInstigator().
 */
UFUNCTION(Category = "Tutorials", Meta = (AutoSplit = "Prompt", ExpandToEnum = "Prompt_Action", ExpandedEnum = "/Script/Angelscript.ActionNames", AdvancedDisplay = "AttachComponent,AttachOffset,ScreenSpaceOffset"))
void ShowTutorialPromptWorldSpace(AHazePlayerCharacter Player, FTutorialPrompt Prompt, UObject Instigator, USceneComponent AttachComponent = nullptr, FVector AttachOffset = FVector(0.f, 0.f, 176.f), float ScreenSpaceOffset = 100.f)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	if (Prompt.Text.IsInitializedFromString())
	{
		PrintScaled(
			"Tutorial prompt trying to show text '"+Prompt.Text+"' was initialized using FText::FromString"
			+"\nThis breaks translation, so please use NSLOCTEXT or put it in a UPROPERTY() instead!",
		30.f, FLinearColor(1.f, 0.5f, 0.f), 2.f);
		ensure(false);
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddWorldPrompt(Prompt, Instigator, AttachComponent, AttachOffset, ScreenSpaceOffset);
}

/**
 * Remove any tutorial prompts or chains that were added with the specified instigator.
 */
UFUNCTION(Category = "Tutorials")
void RemoveTutorialPromptByInstigator(AHazePlayerCharacter Player, UObject Instigator)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
    if (TutorialComponent != nullptr)
		TutorialComponent.RemoveTutorialsByInstigator(Instigator);
}

UFUNCTION(Category = "Tutorials")
void ShowCancelPrompt(AHazePlayerCharacter Player, UObject Instigator)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddCancelPrompt(false, FText(), Instigator);
}

UFUNCTION(Category = "Tutorials")
void ShowCancelPromptWithText(AHazePlayerCharacter Player, UObject Instigator, FText CustomText)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	if (CustomText.IsInitializedFromString())
	{
		PrintScaled(
			"Cancel prompt trying to show text '"+CustomText+"' was initialized using FText::FromString"
			+"\nThis breaks translation, so please put it in a UPROPERTY() instead!",
		30.f, FLinearColor(1.f, 0.5f, 0.f), 2.f);
		ensure(false);
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddCancelPrompt(true, CustomText, Instigator);
}

UFUNCTION(Category = "Tutorials")
void RemoveCancelPromptByInstigator(AHazePlayerCharacter Player, UObject Instigator)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
    if (TutorialComponent != nullptr)
		TutorialComponent.RemoveCancelPrompt(Instigator);
}

// This will change the valid status flag on the widget, if there is one
UFUNCTION(Category = "Tutorials")
void MakeCancelPromptValid(AHazePlayerCharacter Player, bool bStatus)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
    if (TutorialComponent != nullptr)
	{
		auto CancelWidget = Cast<UCancelPromptWidget>(TutorialComponent.CancelPrompt);
		if(CancelWidget != nullptr)
		{
			CancelWidget.bIsAllowedToCancel = bStatus;
			CancelWidget.Update();
		}
	}
}

// This will fire the clicked event on the prompt widget, if there is one.
UFUNCTION(Category = "Tutorials")
void MakeCancelPromptClicked(AHazePlayerCharacter Player)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
    if (TutorialComponent != nullptr)	
	{
		auto CancelWidget = Cast<UCancelPromptWidget>(TutorialComponent.CancelPrompt);
		if(CancelWidget != nullptr)
		{
			CancelWidget.OnCancelPressed();
		}
	}
}