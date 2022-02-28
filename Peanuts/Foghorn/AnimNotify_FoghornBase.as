import Peanuts.Foghorn.AnimNotifyEditorStateManager;

UCLASS(Abstract)
class AnimNotify_FoghornBase : UAnimNotify
{
	// Will ONLY use the preview actor, only supporting Bark & Efforts.
	UPROPERTY(EditAnywhere, Category = "Parameters")
	bool bPlayInPreview = false;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (MeshComp.GetOwner() == nullptr)			
			return true;

		#if EDITOR
		if (MeshComp.GetWorld() != nullptr && !World.IsGameWorld())
		{
			PlaySoundInEditor();
			return true;
		}
		#endif

		if (!ValidNotifyForPlay(MeshComp, Animation))
			return true;

		Play(MeshComp, Animation);
		return true;
	}

	bool ValidNotifyForPlay(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		return true;
	}

	void Play(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{

	}

	AActor GetActorOverride(USkeletalMeshComponent MeshComp) const
	{
		if (BarkDataAsset != nullptr) 
		{
			if (BarkDataAsset.Character == EFoghornActor::May || BarkDataAsset.Character == EFoghornActor::Cody)
				return nullptr;

			return MeshComp.Owner;
		}

		return nullptr;
	}

	UFoghornBarkDataAsset GetBarkDataAsset() const property
	{
		return nullptr;
	}

	UFoghornDialogueDataAsset GetDialogueDataAsset() const property
	{
		return nullptr;
	}

	#if EDITOR

	void PlaySoundInEditor() const
	{
		if (!bPlayInPreview) 
			return;

		const auto bHasData =  BarkDataAsset != nullptr || DialogueDataAsset != nullptr;

		if (!bHasData) 
		{
			Print("No DataAsset hasn't been assigned!");
			return;
		}

		if (BarkDataAsset != nullptr) 
		{
			if (BarkDataAsset.VoiceLines.Num() == 0)
				return;

			int Index = GetAnimNotifyEditiorStateManager().GetNextPreviewVoiceLineIndex(BarkDataAsset.Name, BarkDataAsset.VoiceLines.Num());
			const auto AudioEvent = BarkDataAsset.VoiceLines[Index].AudioEvent;
			if (AudioEvent != nullptr)
			{
				AkGameplay::PostEventOnDummyObject(AudioEvent);
			}
		}

		if (DialogueDataAsset != nullptr) 
		{
			if (DialogueDataAsset.VoiceLines.Num() == 0)
				return;

			int Index = GetAnimNotifyEditiorStateManager().GetNextPreviewVoiceLineIndex(DialogueDataAsset.Name, BarkDataAsset.VoiceLines.Num());
			const auto AudioEvent = DialogueDataAsset.VoiceLines[Index].AudioEvent;
			if (AudioEvent != nullptr)
			{
				AkGameplay::PostEventOnDummyObject(AudioEvent);
			}
		}
	}

	#endif

}