#if EDITOR
class UAnimNotifyEditiorStateManager
{
	private TMap<FName, int> VoiceLineNextIndex;

	int GetNextPreviewVoiceLineIndex(FName AssetName, int NumVoiceLines)
	{
		int Index = VoiceLineNextIndex.FindOrAdd(AssetName);
		int NewIndex = (Index + 1) % NumVoiceLines;
		VoiceLineNextIndex[AssetName] = NewIndex;
		return Index;
	}

}

UFUNCTION(NotBlueprintCallable)
UAnimNotifyEditiorStateManager GetAnimNotifyEditiorStateManager()
{
	return Cast<UAnimNotifyEditiorStateManager>(UAnimNotifyEditiorStateManager::StaticClass().GetDefaultObject());
}
#endif