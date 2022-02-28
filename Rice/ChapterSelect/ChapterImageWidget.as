
class UChapterImageWidget : UHazeUserWidget
{
	UPROPERTY()
	FHazeChapter Chapter;

	bool bLoadingTexture = false;

	UFUNCTION()
	void SetChapter(FHazeChapter InChapter)
	{
		bLoadingTexture = true;
		Chapter = InChapter;
		UHazeChapterDatabase::LoadChapterTexture(Chapter, FOnChapterTextureLoaded(this, n"OnTextureLoaded"));

		if (bLoadingTexture)
			BP_StartedLoadingImage();
	}

	UFUNCTION()
	private void OnTextureLoaded(FHazeChapter InChapter, UMaterialInstanceConstant Texture)
	{
		// Ignore previous loads of textures
		if (InChapter.ProgressPoint.InLevel != Chapter.ProgressPoint.InLevel)
			return;
		if (InChapter.ProgressPoint.Name != Chapter.ProgressPoint.Name)
			return;

		bLoadingTexture = false;
		BP_FinishedLoadingImage(Texture);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartedLoadingImage() {}
	UFUNCTION(BlueprintEvent)
	void BP_FinishedLoadingImage(UMaterialInstanceConstant Image) {}
}