import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

event void FOnMenuPromptPressed();

enum EMenuPromptState
{
	ClickableOnly,
	ButtonPromptOnly,
	ClickableWithKeyboardPrompt,
	ClickableWithControllerPrompt,
	Hidden,
};

class UMenuPromptOrButton : UHazeUserWidget
{
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY()
	FText Text;

	UPROPERTY()
	FText NarrationText;

	UPROPERTY()
	FKey PromptKey;

	UPROPERTY()
	FKey PromptKeyboardKey;

	UPROPERTY()
	EHazeSpecialInputButton PromptSpecialButton = EHazeSpecialInputButton::None;

	UPROPERTY()
	bool bCanBeClicked = true;

	UPROPERTY(BlueprintReadWrite)
	bool bPlaySoundOnHover = true;

	private bool bHovered = false;
	private bool bIsPressed = false;
	private float RepeatTimer = 0.2f;

	UPROPERTY()
	FOnMenuPromptPressed OnPressed;

	UPROPERTY()
	FOnMenuPromptPressed OnRepeat;

	UFUNCTION()
	void Update()
	{
		BP_Update();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Update() {}

	UFUNCTION(BlueprintPure)
	bool IsButtonHovered()
	{
		return bHovered && bCanBeClicked;
	}

	UFUNCTION(BlueprintPure)
	bool IsButtonPressed()
	{
		return bIsPressed && bCanBeClicked;
	}

	UFUNCTION(BlueprintPure)
	bool IsClickableByMouse()
	{
		return !Game::IsConsoleBuild() && bCanBeClicked;
	}

	UFUNCTION(BlueprintPure)
	bool IsUsableByController()
	{
		return PromptKey.IsValid() || PromptSpecialButton != EHazeSpecialInputButton::None;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bIsPressed)
		{
			RepeatTimer -= InDeltaTime;
			if (RepeatTimer <= 0.f)
			{
				OnRepeat.Broadcast();
				RepeatTimer = 0.1f;
			}
		}
	}

	UFUNCTION(BlueprintPure)
	EMenuPromptState GetPromptState()
	{
		if (IsClickableByMouse())
		{
			if (IsUsableByController())
			{
				if (GetControllerType() == EHazePlayerControllerType::Keyboard)
					return EMenuPromptState::ClickableOnly;
				else
					return EMenuPromptState::ButtonPromptOnly;
			}
			else
			{
				return EMenuPromptState::ClickableOnly;
			}
		}
		else
		{
			if (IsUsableByController())
				return EMenuPromptState::ButtonPromptOnly;
			else
				return EMenuPromptState::Hidden;
		}
	}

	UFUNCTION(BlueprintPure)
	EHazePlayerControllerType GetControllerType()
	{
		EHazePlayerControllerType Type = Lobby::GetMostLikelyControllerType();
		if (Type == EHazePlayerControllerType::Keyboard && !IsClickableByMouse())
			return EHazePlayerControllerType::Xbox;
		return Type;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry Geom, FPointerEvent MouseEvent)
	{
		bHovered = true;
		if(bPlaySoundOnHover)
			GetAudioManager().UI_OnSelectionChanged_Mouse();
		Game::NarrateText(Text);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bIsPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{
			bIsPressed = true;
			RepeatTimer = 0.5f;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDoubleClick(FGeometry InMyGeometry, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{
			bIsPressed = true;
			RepeatTimer = 0.5f;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton && bIsPressed)
		{
			bIsPressed = false;
			OnPressed.Broadcast();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintEvent)
	FText GetInputButtonNarrationName() property
	{
		return FText();
	}

	bool MakeNarrationString(FString& OutNarrationString)
	{
		if (GetPromptState() != EMenuPromptState::ButtonPromptOnly)
			return false;

		if (!IsVisible())
			return false;

		EHazePlayerControllerType ConType = Lobby::GetMostLikelyControllerType();

		if (ConType == EHazePlayerControllerType::Keyboard)
		{
			if (!PromptKeyboardKey.IsValid())
				return false;

			OutNarrationString = PromptKeyboardKey.GetDisplayName().ToString();
		}
		else
		{
			if (PromptSpecialButton == EHazeSpecialInputButton::Virtual_Accept)
			{
				OutNarrationString = Game::KeyToNarrationText(EKeys::Virtual_Accept, ConType).ToString();
			}
			else if(PromptSpecialButton == EHazeSpecialInputButton::Virtual_Back)
			{
				OutNarrationString = Game::KeyToNarrationText(EKeys::Virtual_Back, ConType).ToString();
			}
			else if (PromptKey.IsValid())
			{
				OutNarrationString = Game::KeyToNarrationText(PromptKey, ConType).ToString();
			}
			else
			{
				return false;
			}
		}

		if (!NarrationText.IsEmptyOrWhitespace())
			OutNarrationString += ", " + NarrationText.ToString();
		else if (!Text.IsEmptyOrWhitespace())
			OutNarrationString += ", " + Text.ToString();

		return true;
	}
};
