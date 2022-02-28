
class USetPlatformableTagsActionUtility : UAssetActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return UStaticMesh::StaticClass();
	}

	UFUNCTION(CallInEditor, Category = "Mesh Tags")
	void AddPlatformableTags()
	{
		for (UObject AssetObj : EditorUtility::GetSelectedAssets())
		{
			UStaticMesh Mesh = Cast<UStaticMesh>(AssetObj);
			if (Mesh != nullptr)
			{
				Mesh.Modify();

				Mesh.SetOverrideStaticComponentTag(n"WallSlideable", bOverride = true, bValue = true);
				Mesh.SetOverrideStaticComponentTag(n"WallRunnable", bOverride = true, bValue = true);
				Mesh.SetOverrideStaticComponentTag(n"LedgeGrabbable", bOverride = true, bValue = true);
				Mesh.SetOverrideStaticComponentTag(n"LedgeVaultable", bOverride = true, bValue = true);
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "Mesh Tags")
	void RemovePlatformableTags()
	{
		for (UObject AssetObj : EditorUtility::GetSelectedAssets())
		{
			UStaticMesh Mesh = Cast<UStaticMesh>(AssetObj);

			if (Mesh != nullptr)
			{
				Mesh.Modify();

				Mesh.SetOverrideStaticComponentTag(n"WallSlideable", bOverride = false, bValue = false);
				Mesh.SetOverrideStaticComponentTag(n"WallRunnable", bOverride = false, bValue = false);
				Mesh.SetOverrideStaticComponentTag(n"LedgeGrabbable", bOverride = false, bValue = false);
				Mesh.SetOverrideStaticComponentTag(n"LedgeVaultable", bOverride = false, bValue = false);
			}
		}
	}
};