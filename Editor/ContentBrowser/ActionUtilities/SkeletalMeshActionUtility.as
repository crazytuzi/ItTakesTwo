class USkeletalMeshActionUtility : UAssetActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return USkeletalMesh::StaticClass();
	}

	UFUNCTION(CallInEditor, Category = "Performance")
	void Foo()
	{
		for (UObject AssetObj : EditorUtility::GetSelectedAssets())
		{
			USkeletalMesh SkeletalMesh = Cast<USkeletalMesh>(AssetObj);
			if( SkeletalMesh == nullptr )
				continue;

			EditorSkeletalMesh::RegenerateLOD(SkeletalMesh, 0, true, false); // The LODs will be shit after this
			// so we will want to run a reimport to get back the actual LODs now that we've purged the previous lod info

			// https://docs.unrealengine.com/en-US/API/Runtime/Engine/Engine/FSkeletalMeshLODInfo/LODMaterialMap/index.html
			// for (FSkeletalMeshLODInfo LODInfo : SkeletalMesh.LODInfo)
			// {
			// 	// continue; // Ok LODInfo didn't have any access to the material array ... at least not here...
			// }
		}
	}
}