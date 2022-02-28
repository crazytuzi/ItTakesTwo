class UInputButtonWidget : UHazeInputButton
{
};

class UInputStickWidget : UHazeUserWidget
{
	EHazePlayerControllerType DisplayedControllerType;

	AHazePlayerCharacter InputPlayer;
	UHazeInputComponent InputComp;

	UFUNCTION(BlueprintPure)
	EHazePlayerControllerType GetControllerType()
	{
		if (InputComp != nullptr)
			return InputComp.GetControllerType();
		return Lobby::GetMostLikelyControllerType();
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		DisplayedControllerType = GetControllerType();

		InputPlayer = Player;
		InputComp = UHazeInputComponent::Get(InputPlayer);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnControllerTypeChanged() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (DisplayedControllerType != GetControllerType())
		{
			DisplayedControllerType = GetControllerType();
			BP_OnControllerTypeChanged();
		}

		if (InputPlayer != Player)
		{
			InputPlayer = Player;
			InputComp = UHazeInputComponent::Get(InputPlayer);
		}
	}
};