import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsActor;
import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsPromptCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMusicalChairsActor MusicalChairs;

	UMusicalChairsPlayerComponent MayMusicalChairsComp;
	UMusicalChairsPlayerComponent CodyMusicalChairsComp;

	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;
	
	UHazeInputButton FullscreenPlayerRoundButtonWidget = nullptr;
	UHazeInputButton OtherPlayerRoundButtonWidget = nullptr;

	EHazePlayerControllerType CodyControllerType;
	EHazePlayerControllerType MayControllerType;

	UHazeInputComponent CodyInputComp;
	UHazeInputComponent MayInputComp;

	bool bPromptDelayFinished = false;

	float PromptDelayTimer = 0.0f;
	float PromptDelayDuration = 1.0f;

	bool bShowingPrompt = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MusicalChairs = Cast<AMusicalChairsActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MusicalChairs.bShowButtonPrompt)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MusicalChairs.bShowButtonPrompt)
			return EHazeNetworkDeactivation::DontDeactivate;
		else if(!bPromptDelayFinished)
			return EHazeNetworkDeactivation::DontDeactivate;
		else
			return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		May = Game::GetMay();
		Cody = Game::GetCody();

		CodyInputComp = UHazeInputComponent::Get(Cody);
		MayInputComp = UHazeInputComponent::Get(May);
		
		MayMusicalChairsComp = UMusicalChairsPlayerComponent::Get(May);
		CodyMusicalChairsComp = UMusicalChairsPlayerComponent::Get(Cody);
		
		ShowButtonPrompts();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveWidgets();
		PromptDelayTimer = 0.0f;
		bPromptDelayFinished = false;
	}

	void RemoveWidgets()
	{
		if(FullscreenPlayerRoundButtonWidget != nullptr)
		{
			MusicalChairs.FullscreenedPlayer.RemoveWidget(FullscreenPlayerRoundButtonWidget);
			FullscreenPlayerRoundButtonWidget = nullptr;
		}

		if(OtherPlayerRoundButtonWidget != nullptr)
		{
			MusicalChairs.FullscreenedPlayer.OtherPlayer.RemoveWidget(OtherPlayerRoundButtonWidget);
			OtherPlayerRoundButtonWidget = nullptr;
		}

		bShowingPrompt = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(MayControllerType != MayInputComp.GetControllerType() || CodyControllerType != CodyInputComp.GetControllerType())
		{
			ShowButtonPrompts();
		}

		if(!MusicalChairs.bShowButtonPrompt && !bPromptDelayFinished)
		{
			PromptDelayTimer += DeltaTime;

			if(PromptDelayTimer >= PromptDelayDuration)
			{
				bPromptDelayFinished = true;
			}
		}
	}


	UFUNCTION()
	void ShowButtonPrompts()
	{
		if(bShowingPrompt)
			RemoveWidgets();
		
		CodyControllerType = CodyInputComp.GetControllerType();
		MayControllerType = MayInputComp.GetControllerType();

		bool bDifferentControllerTypes = false;

		if(CodyControllerType != MayControllerType)
			bDifferentControllerTypes = true;

		FName WidgetsActionName = GetActionNameForWidget(MusicalChairs.RoundButtonType);

		FullscreenPlayerRoundButtonWidget = Cast<UHazeInputButton>(MusicalChairs.FullscreenedPlayer.AddWidget(MusicalChairs.InputButtonClass));
		
		if(bDifferentControllerTypes)
		{
			if(MusicalChairs.FullscreenedPlayer.IsMay())
				FullscreenPlayerRoundButtonWidget.AttachWidgetToComponent(MusicalChairs.MaySpecificButtonPromptRoot);
			else
				FullscreenPlayerRoundButtonWidget.AttachWidgetToComponent(MusicalChairs.CodySpecificButtonPromptRoot);
		}
		else
		{
			FullscreenPlayerRoundButtonWidget.AttachWidgetToComponent(MusicalChairs.ButtonPromptRoot);
		}
	
		FullscreenPlayerRoundButtonWidget.ActionName = WidgetsActionName;
		FullscreenPlayerRoundButtonWidget.SetWidgetShowInFullscreen(true);

		if(bDifferentControllerTypes)
		{
			OtherPlayerRoundButtonWidget = Cast<UHazeInputButton>(MusicalChairs.FullscreenedPlayer.OtherPlayer.AddWidget(MusicalChairs.InputButtonClass));

			if(MusicalChairs.FullscreenedPlayer.OtherPlayer.IsMay())
				OtherPlayerRoundButtonWidget.AttachWidgetToComponent(MusicalChairs.MaySpecificButtonPromptRoot);
			else
				OtherPlayerRoundButtonWidget.AttachWidgetToComponent(MusicalChairs.CodySpecificButtonPromptRoot);

			OtherPlayerRoundButtonWidget.ActionName = WidgetsActionName;

			OtherPlayerRoundButtonWidget.SetWidgetShowInFullscreen(true);
		}

		bShowingPrompt = true;
	}


	UFUNCTION()
	FName GetActionNameForWidget(EMusicalChairsButtonType ButtonType)
	{
		switch(ButtonType)
		{
			case EMusicalChairsButtonType::BottomFaceButton:
			{
				return ActionNames::MinigameBottom;
			}

			case EMusicalChairsButtonType::LeftFaceButton:
			{
				return ActionNames::MinigameLeft;
			}

			case EMusicalChairsButtonType::RightFaceButton:
			{
				return ActionNames::MinigameRight;
			}

			case EMusicalChairsButtonType::TopFaceButton:
			{
				return ActionNames::MinigameTop;
			}
		}
		return NAME_None;
	}
	
}