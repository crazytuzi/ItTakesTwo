/*
 * Due to most tilers originally supporting the max allowed slots, we will want to have a tool for quickly
 * replacing tiler materials to a parent which supports the correct number of slots for the given instance.
 */
 
// TODO: Add filter so this utility only shows for Material Instances with tiler as their base,

class UTilerMaterialsInstance : UAssetActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return UMaterialInstanceConstant::StaticClass();
	}

	// Utility function to get the number of used slots in a Tiler,
	int GetNumberOfUsedSlots(UMaterialInstanceConstant MaterialInstance)
	{
		UMaterial BaseMaterial = MaterialInstance.GetBaseMaterial();
		
		// Hardcoded matching for the name of our tiler material,
		// If the Material Instance don't use tiler as base, exit.
		if (BaseMaterial.GetName() != "Master_Env_Tiler")
			return 0;

		// A tiler can use anywhere from 1..3 slots,
		int NumSlots = 1;

		if(0.0f < MaterialInstance.GetScalarParameterValue(FName("HazeToggleCategory_Tiler_B Enabled")))
			NumSlots += 1;

		if(0.0f < MaterialInstance.GetScalarParameterValue(FName("HazeToggleCategory_Tiler_C Enabled")))
			NumSlots += 1;

		return NumSlots;
	}

	UFUNCTION(CallInEditor, Category = "Performance")
	void TrimSlots()
	{
		for (UObject AssetObj : EditorUtility::GetSelectedAssets())
		{
			UMaterialInstanceConstant MaterialInstance = Cast<UMaterialInstanceConstant>(AssetObj);
			if (MaterialInstance == nullptr)
				continue;
			
			// For now assumtion will be made that the instance is direct child to our different tilers,
			int NumberOfUsedSlots = GetNumberOfUsedSlots(MaterialInstance);

			if(NumberOfUsedSlots < 1)
			{
				Print("An attempt was made, but this is no tiler.");
				continue;
			}				

			// Print(MaterialInstance.Parent.GetPathName());
			FString ParentName = MaterialInstance.Parent.GetName();

			// Scan the name for the first occurence of a digit, which we will attempt replace with str of number of slots,
			FString PreviousDigit = FString();
			for(int i=0; i<ParentName.Len(); i++)
			{
				FString Char = ParentName.Mid(i, 1);
				if(Char.IsNumeric())
				{
					PreviousDigit = Char;
					break;
				}
			}

			FString NewParentName = ParentName.Replace(PreviousDigit, ""+NumberOfUsedSlots);

			// Attempt finding the tiler material which matches the number of slots used,
			FName AssetName = FName(MaterialInstance.Parent.GetPathName().Replace(ParentName, NewParentName));
			UObject LoadedAsset = Editor::LoadAsset(AssetName);
			UMaterialInterface Parent = Cast<UMaterialInterface>(LoadedAsset);
			if(Parent ==  nullptr)
			{
				Print("Failed to load " + AssetName + " as a UMaterialInterface");
				continue;
			}				

			// If the material was found, replace the previous one with the lower number of slots, which should save about 1k instuctions for each slot trimmed,
			MaterialEditing::SetMaterialInstanceParent(MaterialInstance, Parent);
			MaterialInstance.Modify(); // Mark the Material Instance as dirty,
		}
	}
}