class FilterSpringArmAssetsUsingCameraOffsetOwnerSpace : UHazeScriptContentBrowserFilter
{
	default Color = FLinearColor::Red;
	default FilterName = "CameraOffsetOwnerSpace Users";
	default Tooltip = "Filters for those camera spring arm assets that will change CameraOffsetOwnerSpace";

	UFUNCTION(BlueprintOverride)
	bool IsAllowedByFilter(FName ObjectPath, FName AssetClass, FName AssetName, FName PackageName, FName PackagePath) const
	{
		// If you are going to load assets, always filter by AssetClass or something else before, or you might be loading horrible amounts of assets!
		if (AssetClass != n"HazeCameraSpringArmSettingsDataAsset")
			return false;
		UHazeCameraSpringArmSettingsDataAsset CamSettings = Cast<UHazeCameraSpringArmSettingsDataAsset>(Editor::LoadAsset(ObjectPath));
		if (CamSettings == nullptr)
			return false;
		if (!CamSettings.SpringArmSettings.bUseCameraOffsetOwnerSpace)		
			return false;
		return true;
	}
}