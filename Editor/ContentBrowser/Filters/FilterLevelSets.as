class FilterLevelSets : UHazeScriptContentBrowserFilter
{
	// What color filter buttion will be shown in when active
	default Color = FLinearColor::Red;

	// Name of the filter in list and button
	default FilterName = "Levelsets";

	// Tooltip shown when hovering over list entry or button
	default Tooltip = "Will show all levelset data assets.";

	// Decides if the asset described by given parameters should be shown in content browser when this filter is active
	// Note that you can change and recompile this when in editor, but you need to deactivate and then activate 
	// filter again for the change to have an effect
	// Parameters are
	// ObjectPath 	The full path needed to load an asset
	// AssetClass 	Name of the class of the given asset, without any package information (so can't be used to load the class)
	// AssetName  	Name of the asset, i.e. tail part of the ObjectPath
	// PackageName 	Name of the asset package including path, i.e. <ObjectPath> == <PackageName><AssetName>
	// PackagePath 	The path to the package i.e. PackageName without the ending name. 
	UFUNCTION(BlueprintOverride)
	bool IsAllowedByFilter(FName ObjectPath, FName AssetClass, FName AssetName, FName PackageName, FName PackagePath) const
	{
		// Always do name and string comparisons of asset data before trying to load assets!
		if (AssetClass != n"HazeLevelSetAsset")
			return false;
		return true;
	}
}