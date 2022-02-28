// By inheriting from UHazeCustomContextMenuAction the ShouldAddMenuEntry... methods will determine if 
// a menu entry will be added to the right-click menu in the content browser.
// The PerformActionFor... methods will be called when selecting that entry.
class Example_ContentBrowserContextMenuAction : UHazeCustomContextMenuAction
{
	// This text will be shown in the menu
	default MenuLabel = FText::FromString("Example Custom Action");

	// This text will be shown if hovering over the menu entry
	default MenuTooltip = FText::FromString("This will open the editor for the ten first selected float curve assets.");

	// Return true if you want a menu entry when the user has selected the given path(s).
	// Note that you should make this as cheap as possible, so use paths comparisons first if you can.
	UFUNCTION(BlueprintOverride)
	bool ShouldAddMenuEntryForPaths(TArray<FString> SelectedPaths) const
	{
		// Only use this if any paths contain specific substrings and have assets.
		TArray<FHazeAssetData> Assets;
		if (!FindAssetsFromValidPaths(SelectedPaths, Assets))
			return false;

		// There were valid paths with assets, check if any of those meet our criteria		
		return ShouldAddMenuEntryForAssets(Assets);
	}
	
	// Helper function to find paths matching specific sub strings (used both in ShouldAddMenuEntryForPaths and PerformActionForPaths)
	bool FindAssetsFromValidPaths(TArray<FString> SelectedPaths, TArray<FHazeAssetData>& OutAssets) const
	{
		// Check for matching substrings
		TArray<FString> ValidPaths;
		for (FString Path : SelectedPaths)
		{
			if (Path.Contains("Developers") || Path.Contains("Test"))
				ValidPaths.Add(Path);	
		}
		if (ValidPaths.Num() == 0)
			return false;

		// Get all assets from the valid paths
		Editor::GetAssetsInPaths(ValidPaths, OutAssets);
		return (OutAssets.Num() > 0);
	}

	// Return true if you want a menu entry when the user has selected the given assets.
	// FHazeAssetData properties are:
	// ObjectPath 	The full path needed to load an asset
	// AssetClass 	Name of the class of the given asset, without any package information (so can't be used to load the class)
	// AssetName  	Name of the asset, i.e. tail part of the ObjectPath
	// PackageName 	Name of the asset package including path, i.e. <ObjectPath> == <PackageName><AssetName>
	// PackagePath 	The path to the package i.e. PackageName without the ending name. 
	UFUNCTION(BlueprintOverride)
	bool ShouldAddMenuEntryForAssets(const TArray<FHazeAssetData>& SelectedAssets) const
	{
		// Check if there are any float curve assets
		for (FHazeAssetData AssetData : SelectedAssets)
		{
			if (AssetData.AssetClass == n"CurveFloat")
				return true;	
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PerformActionForPaths(const TArray<FString>& SelectedPaths)
	{
		// Find potential assets
		TArray<FHazeAssetData> Assets;
		if (FindAssetsFromValidPaths(SelectedPaths, Assets))
			PerformActionForAssets(Assets);
	}

	UFUNCTION(BlueprintOverride)
	void PerformActionForAssets(const TArray<FHazeAssetData>& SelectedAssets)
	{
		// Open editor for the first ten curves
		int NumOpenedAssets = 0;
		for (FHazeAssetData AssetData : SelectedAssets)
		{
			if (AssetData.AssetClass == n"CurveFloat")
			{
				Editor::OpenEditorForAsset(AssetData.ObjectPath.ToString());
				NumOpenedAssets++;
				if (NumOpenedAssets == 10)
					return;
			}
		}
	}
}