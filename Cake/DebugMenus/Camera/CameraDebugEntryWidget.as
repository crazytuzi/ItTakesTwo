class UCameraDebugEntryWidget : UHazeUserWidget
{
	FHazeInstigatedCameraDebugData Data;

	UFUNCTION(BlueprintCallable)
	void SelectCamera()
	{
		if (!CanSelectCamera())
			return;

		if (Editor::IsSelected(Data.Camera.Owner))
			Editor::SelectActor(nullptr); // Unselect
		else 
			Editor::SelectActor(Data.Camera.Owner);
	}

	bool CanSelectCamera()
	{
        if (!Game::IsEditorBuild())
            return false;
		if (Data.Camera == nullptr)
            return false;
		if (Data.Camera.Owner == nullptr)
            return false;
		return true;
	}

    FString GetCameraDescription(UHazeCameraComponent Camera)
    {
        if (Camera == nullptr)
            return "<nullptr>";
        if (Camera.GetOwner() == nullptr)
            return "" + Camera + " with no owner!";
        return Camera.GetOwner().GetName() + " (" + Camera.GetName() + ")";
    }

	void Update(FHazeInstigatedCameraDebugData Data, FText Description)
	{
		this.Data = Data;
		if (!CanSelectCamera())
		{
			HideCameraButton();
			SetDescription(FText::FromString(GetCameraButtonCaption() + "\n" + Description.ToString()));
		}
		else	
		{
			ShowCameraButton(FText::FromString(GetCameraButtonCaption()));
			SetDescription(Description);
		}
	}

	FString GetCameraButtonCaption()
	{
		FString Caption = GetCameraDescription(Data.Camera);
		if (Data.Instigator.IsA(UHazeCameraSelector::StaticClass()))
			Caption = "<Grey>" + Caption + "</>";

		return Caption;
	}

	UFUNCTION(BlueprintEvent)
	void ShowCameraButton(FText Caption)
	{
	}

	UFUNCTION(BlueprintEvent)
	void HideCameraButton()
	{
	}

	UFUNCTION(BlueprintEvent)
	void SetDescription(FText Description)
	{
	}
}