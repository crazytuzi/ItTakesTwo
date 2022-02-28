class UCameraSettingsDebugEntryWidget : UHazeUserWidget
{
	FHazeInstigatedCameraSettingsDebugData Data;

	UFUNCTION(BlueprintCallable)
	void OpenSettingsAssetEditor()
	{
        if (!Game::IsEditorBuild())
            return;
		if (Data.SettingsAsset == nullptr)
			return;

		Editor::OpenEditorForAsset(Data.SettingsAsset.GetPathName());
	}

	void Update(FHazeInstigatedCameraSettingsDebugData Data, FText Description)
	{
		this.Data = Data;
		if (Data.SettingsAsset == nullptr)
			HideAssetButton();
		else	
			ShowAssetButton(GetAssetButtonCaption());

		SetDescription(Description);
	}

	FText GetAssetButtonCaption()
	{
		FString Caption = Data.SettingsAsset.GetName();
		if (Data.Instigator == Game::GetHazeGameInstance())
			Caption = "<Grey>" + Caption + "</>";
		else if (Data.bIsBlendingOut)
			Caption = "<LightGrey>" + Caption + "</>";
		return FText::FromString(Caption);
	}

	UFUNCTION(BlueprintEvent)
	void ShowAssetButton(FText Caption)
	{
	}

	UFUNCTION(BlueprintEvent)
	void HideAssetButton()
	{
	}

	UFUNCTION(BlueprintEvent)
	void SetDescription(FText Description)
	{
	}
}