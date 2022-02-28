import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialWidget;
import Vino.Tutorial.CancelPromptWidget;

struct FActiveTutorial
{
	int TutorialId = 0;
	FTutorialPrompt Prompt;
	float Timer = 0.f;
	UObject Instigator;
	USceneComponent Attach;
	FVector Offset;
	UTutorialPromptWidget PromptWidget;
	float ScreenSpaceOffset = 0.f;
};

struct FActiveTutorialChain
{
	int TutorialId = 0;
	FTutorialPromptChain Chain;
	int ChainPosition = 0;
	UObject Instigator;
};

struct FCancelPrompt
{
	bool bCustomText = false;
	FText CancelText;
	UObject Instigator;
};

UCLASS(HideCategories = "ComponentReplication Activation Cooking Collision")
class UTutorialComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UTutorialContainerWidget> TutorialWidget;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> CancelPromptWidget;

	UPROPERTY()
	TSubclassOf<UTutorialPromptWidget> WorldPromptWidget;

	UPROPERTY()
	TArray<FCancelPrompt> CancelPrompts;

	bool bHasTutorials = false;
	TArray<FActiveTutorial> ActiveTutorials;
	TArray<FActiveTutorialChain> ActiveChains;
	int NextTutorialId = 0;

	TArray<FActiveTutorial> WorldPrompts;

	AHazePlayerCharacter Player;
	UCancelPromptWidget CancelPrompt;
	TArray<UTutorialPromptWidget> WorldPromptWidgets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0, Count = ActiveTutorials.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = ActiveTutorials[i];
			Tutorial.Timer += DeltaTime;

			// Remove tutorials that have reached their max duration
			if (Tutorial.Prompt.MaximumDuration > 0.f)
			{
				if (Tutorial.Timer > Tutorial.Prompt.MaximumDuration)
				{
					ActiveTutorials.RemoveAt(i);
					--i; --Count;
				}
			}
		}

		if (ActiveTutorials.Num() == 0 && ActiveChains.Num() == 0)
		{
			bHasTutorials = false;
			SetComponentTickEnabled(false);
		}
	}

	void AddCancelPrompt(bool bCustomText, FText Text, UObject Instigator)
	{
		FCancelPrompt Prompt;
		Prompt.bCustomText = bCustomText;
		Prompt.CancelText = Text;
		Prompt.Instigator = Instigator;

		CancelPrompts.Add(Prompt);
		UpdateCancelWidget();
	}

	void RemoveCancelPrompt(UObject Instigator)
	{
		for (int i = CancelPrompts.Num() - 1; i >= 0; --i)
		{
			if (CancelPrompts[i].Instigator == Instigator)
			{
				CancelPrompts.RemoveAt(i);
			}
		}

		UpdateCancelWidget();
	}

	void UpdateCancelWidget()
	{
		if (CancelPrompt != nullptr)
		{
			if (CancelPrompts.Num() == 0)
			{
				Player.RemoveWidgetFromHUD(CancelPrompt);
				CancelPrompt = nullptr;
			}
		}
		else
		{
			if (CancelPrompts.Num() != 0)
			{
				CancelPrompt = Cast<UCancelPromptWidget>(Player.AddWidgetToHUDSlot(n"CancelPrompt", CancelPromptWidget));
			}
		}

		if (CancelPrompts.Num() != 0 && CancelPrompt != nullptr)
		{
			if (CancelPrompts.Last().bCustomText)
				CancelPrompt.CancelText = CancelPrompts.Last().CancelText;
			else
				CancelPrompt.CancelText = CancelPrompt.DefaultCancelText;
			CancelPrompt.Update();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		bHasTutorials = false;
		ActiveTutorials.Empty();
		ActiveChains.Empty();
		CancelPrompts.Empty();
		UpdateCancelWidget();

		for (auto& ActivePrompt : WorldPrompts)
		{
			if (ActivePrompt.PromptWidget != nullptr)
				Player.RemoveWidget(ActivePrompt.PromptWidget);
		}
		WorldPrompts.Empty();
		UpdateWorldPromptWidgets();
	}

	void AddTutorial(FTutorialPrompt Prompt, UObject Instigator)
	{
		// We don't accept tutorials that go away on their own
		// on the remote side, since we can't properly remove them
		if (!HasControl() && Prompt.Mode != ETutorialPromptMode::Default)
			return;

		FActiveTutorial Tutorial;
		Tutorial.Prompt = Prompt;
		Tutorial.Instigator = Instigator;
		Tutorial.TutorialId = NextTutorialId++;

		ActiveTutorials.Add(Tutorial);

		bHasTutorials = true;
		SetComponentTickEnabled(true);
	}

	void AddTutorialChain(FTutorialPromptChain PromptChain, UObject Instigator, int InitialPosition)
	{
		FActiveTutorialChain Chain;
		Chain.Chain = PromptChain;
		Chain.Instigator = Instigator;
		Chain.TutorialId = NextTutorialId++;
		Chain.ChainPosition = InitialPosition;

		ActiveChains.Add(Chain);

		bHasTutorials = true;
		SetComponentTickEnabled(true);
	}

	void SetChainPosition(UObject Instigator, int ChainPosition)
	{
		for (int i = 0, Count = ActiveChains.Num(); i < Count; ++i)
		{
			FActiveTutorialChain& Tutorial = ActiveChains[i];
			if (Tutorial.Instigator == Instigator)
				Tutorial.ChainPosition = ChainPosition;
		}
	}

	void RemoveTutorialsByInstigator(UObject Instigator)
	{
		for (int i = 0, Count = ActiveTutorials.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = ActiveTutorials[i];
			if (Tutorial.Instigator == Instigator)
			{
				ActiveTutorials.RemoveAt(i);
				--i; --Count;
			}
		}

		for (int i = 0, Count = ActiveChains.Num(); i < Count; ++i)
		{
			FActiveTutorialChain& Tutorial = ActiveChains[i];
			if (Tutorial.Instigator == Instigator)
			{
				ActiveChains.RemoveAt(i);
				--i; --Count;
			}
		}

		bool bWorldPromptsChanged = false;
		for (int i = WorldPrompts.Num() - 1; i >= 0; --i)
		{
			if (WorldPrompts[i].Instigator == Instigator)
			{
				if (WorldPrompts[i].PromptWidget != nullptr)
					Player.RemoveWidget(WorldPrompts[i].PromptWidget);
				WorldPrompts.RemoveAt(i);
				bWorldPromptsChanged = true;
			}
		}

		if (bWorldPromptsChanged)
			UpdateWorldPromptWidgets();
	}

	void AddWorldPrompt(FTutorialPrompt Prompt, UObject Instigator, USceneComponent Attach, FVector Offset, float ScreenSpaceOffset)
	{
		FActiveTutorial Tutorial;
		Tutorial.Prompt = Prompt;
		Tutorial.Instigator = Instigator;
		Tutorial.TutorialId = NextTutorialId++;
		Tutorial.Offset = Offset;
		Tutorial.ScreenSpaceOffset = ScreenSpaceOffset;

		if (Attach != nullptr)
			Tutorial.Attach = Attach;
		else
			Tutorial.Attach = Player.Mesh;

		WorldPrompts.Add(Tutorial);
		UpdateWorldPromptWidgets();
	}

	void UpdateWorldPromptWidgets()
	{
		// Add new widgets
		for (int i = 0, Count = WorldPrompts.Num(); i < Count; ++i)
		{
			FActiveTutorial& ActivePrompt = WorldPrompts[i];

			// Don't create a widget if we already have one
			if (ActivePrompt.PromptWidget != nullptr)
				continue;

			// Don't create a widget if we have a previous prompt with the same attach point
			bool bAllowed = true;
			for (int j = 0; j < i; ++j)
			{
				const FActiveTutorial& OtherPrompt = WorldPrompts[j];
				if (OtherPrompt.Attach == ActivePrompt.Attach)
				{
					bAllowed = false;
					break;
				}
			}

			if (!bAllowed)
				continue;

			auto WorldPrompt = Cast<UTutorialPromptWidget>(Player.AddWidget(WorldPromptWidget));
			WorldPrompt.Prompt = ActivePrompt.Prompt;
			WorldPrompt.AttachWidgetToComponent(ActivePrompt.Attach);
			WorldPrompt.SetWidgetRelativeAttachOffset(ActivePrompt.Offset);
			WorldPrompt.SetWidgetShowInFullscreen(true);
			WorldPrompt.bIsWorldSpace = true;
			WorldPrompt.SetRenderTranslation(FVector2D(0.f, -ActivePrompt.ScreenSpaceOffset));
			WorldPrompt.Show();

			ActivePrompt.PromptWidget = WorldPrompt;
		}
	}
};