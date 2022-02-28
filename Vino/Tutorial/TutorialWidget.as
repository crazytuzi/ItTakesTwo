import Vino.Tutorial.TutorialPrompt;

class UTutorialPromptWidget : UHazeUserWidget
{
	int TutorialId = 0;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt Prompt;

	UPROPERTY(BlueprintReadOnly)
	bool bIsWorldSpace = false;

	UFUNCTION(BlueprintEvent)
	void Show() {}

	UFUNCTION(BlueprintEvent)
	void Hide() {}

	UFUNCTION(BlueprintPure)
	bool ShowAsStickIcon()
	{
		if (Prompt.DisplayType == ETutorialPromptDisplay::Action)
			return false;
		if (Prompt.DisplayType == ETutorialPromptDisplay::ActionHold)
			return false;

		if (Prompt.DisplayType == ETutorialPromptDisplay::LeftStick_Press
			|| Prompt.DisplayType == ETutorialPromptDisplay::RightStick_Press)
		{
			// Stick press degrades to 'Action' display on Keyboard
			auto InputComp = UHazeInputComponent::Get(Player);
			auto ControllerType = InputComp.GetControllerType();
			if (ControllerType == EHazePlayerControllerType::Keyboard)
				return false;
		}

		return true;
	}
};

class UTutorialPromptChainWidget : UHazeUserWidget
{
	int TutorialId = 0;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPromptChain PromptChain;

	UPROPERTY(BlueprintReadOnly)
	int ChainPosition = 0;

	UFUNCTION(BlueprintEvent)
	UTutorialPromptWidget GetTutorialForPosition(int Position)
	{
		return nullptr;
	}

	void UpdateInnerTutorials()
	{
		for (int i = 0, Count = PromptChain.Prompts.Num(); i < Count; ++i)
		{
			auto Widget = GetTutorialForPosition(i);
			if (Widget != nullptr)
			{
				Widget.Prompt = PromptChain.Prompts[i];
				Widget.Show();
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void Show() {}

	UFUNCTION(BlueprintEvent)
	void Hide() {}
};

class UTutorialContainerWidget : UHazeUserWidget
{
	UPROPERTY()
	TSubclassOf<UTutorialPromptWidget> PromptWidgetClass;

	UPROPERTY()
	TSubclassOf<UTutorialPromptChainWidget> ChainWidgetClass;

	private TArray<UTutorialPromptWidget> PromptWidgets;
	private TArray<UTutorialPromptWidget> RemovedWidgets;

	private TArray<UTutorialPromptChainWidget> ChainWidgets;

	void AddPrompt(int TutorialId, FTutorialPrompt Prompt)
	{
		UTutorialPromptWidget Widget;
		if (RemovedWidgets.Num() == 0)
		{
			Widget = Cast<UTutorialPromptWidget>(Widget::CreateWidget(this, PromptWidgetClass));
		}
		else
		{
			Widget = RemovedWidgets[0];
			RemovedWidgets.RemoveAtSwap(0);
		}
		
		Widget.TutorialId = TutorialId;
		Widget.Prompt = Prompt;

		PromptWidgets.Add(Widget);

		if(Prompt.OverridePlayer != nullptr)
			Widget.OverrideWidgetPlayer(Prompt.OverridePlayer);
		else if(Widget.Player != Player)
			Widget.OverrideWidgetPlayer(Player);
		
		Widget.Show();

		AddPromptWidget(Widget);
	}

	void AddChain(int TutorialId, FTutorialPromptChain PromptChain, int ChainPosition)
	{
		UTutorialPromptChainWidget Widget = Cast<UTutorialPromptChainWidget>(Widget::CreateWidget(this, ChainWidgetClass));
		Widget.TutorialId = TutorialId;
		Widget.PromptChain = PromptChain;
		Widget.ChainPosition = ChainPosition;

		ChainWidgets.Add(Widget);

		Widget.UpdateInnerTutorials();
		Widget.Show();

		AddChainWidget(Widget);
	}

	void SetChainPosition(int TutorialId, int ChainPosition)
	{
		for (int i = 0, Count = ChainWidgets.Num(); i < Count; ++i)
		{
			if (ChainWidgets[i].TutorialId == TutorialId)
				ChainWidgets[i].ChainPosition = ChainPosition;
		}
	}

	void RemovePrompt(int TutorialId)
	{
		for (int i = 0, Count = PromptWidgets.Num(); i < Count; ++i)
		{
			if (PromptWidgets[i].TutorialId == TutorialId)
			{
				PromptWidgets[i].Hide();
				RemovePromptWidget(PromptWidgets[i]);
				RemovedWidgets.Add(PromptWidgets[i]);

				PromptWidgets.RemoveAt(i);
				--i; --Count;
			}
		}

		for (int i = 0, Count = ChainWidgets.Num(); i < Count; ++i)
		{
			if (ChainWidgets[i].TutorialId == TutorialId)
			{
				ChainWidgets[i].Hide();
				RemoveChainWidget(ChainWidgets[i]);
				ChainWidgets.RemoveAt(i);
				--i; --Count;
			}
		}
	}

	void UpdatePrompts()
	{
		RemovedWidgets.Reset();
	}

	UFUNCTION(BlueprintEvent)
	void AddPromptWidget(UTutorialPromptWidget Widget) {}

	UFUNCTION(BlueprintEvent)
	void RemovePromptWidget(UTutorialPromptWidget Widget) {}

	UFUNCTION(BlueprintEvent)
	void AddChainWidget(UTutorialPromptChainWidget Widget) {}

	UFUNCTION(BlueprintEvent)
	void RemoveChainWidget(UTutorialPromptChainWidget Widget) {}
};