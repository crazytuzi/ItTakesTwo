// In the current folder select the meshes missing LODs

class UMissingLods : UAssetActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return UStaticMesh::StaticClass();
	}

	UFUNCTION(CallInEditor, Category = "Performance")
	void SelectMissingLods()
	{
		for (UObject AssetObj : EditorUtility::GetSelectedAssets())
		{
			UStaticMesh StaticMeshAsset = Cast<UStaticMesh>(AssetObj);
			if(StaticMeshAsset==nullptr)
				continue;

			if(1 < StaticMeshAsset.GetNumLods())
				continue;

			Print(""+StaticMeshAsset.GetName());	
		}
	}

	UFUNCTION(CallInEditor, Category = "Performance")
	void AssignLODs()
	{
		for (UObject AssetObj : EditorUtility::GetSelectedAssets())
		{
			UStaticMesh StaticMeshAsset = Cast<UStaticMesh>(AssetObj);
			if(StaticMeshAsset==nullptr)
				continue;

			// Skip assets with LODs already generated,
			TArray<FEditorScriptingMeshReductionSettings> Settings;

			// for (int i = 0; i < 3; i++)
			// {
			// 	FEditorScriptingMeshReductionSettings Setting;
			// 	Setting.ScreenSize = 1.0 * ();
			// 	Setting.PercentTriangles = 1.0 * x;
			// }
			
			// Setting.ScreenSize
			// Settings.Add();

			// EditorStaticMesh::

			// FEditorScriptingMeshReductionOptions ReductionOptions;
			// ReductionOptions.bAutoComputeLODScreenSize = true;
			// ReductionOptions.ReductionSettings = Settings;
			// EditorStaticMesh::SetLods(StaticMeshAsset, ReductionOptions);
		}
	}
}