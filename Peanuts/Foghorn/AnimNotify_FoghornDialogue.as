import Peanuts.Foghorn.AnimNotify_FoghornBase;
import Peanuts.Foghorn.FoghornStatics;

UCLASS(NotBlueprintable, meta = ("FoghornDialogue"))
class AnimNotify_FoghornDialogue : AnimNotify_FoghornBase
{
	UPROPERTY(EditAnywhere, Category = "Parameters")
	UFoghornDialogueDataAsset DialogueAsset;

	UPROPERTY(EditAnywhere, Category = "Parameters")
	bool bUseActorAsExtraActor = false;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FoghornDialogue";
	}

	void Play(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		PlayFoghornDialogue(DialogueAsset, GetActorOverride(MeshComp));
	}

	AActor GetActorOverride(USkeletalMeshComponent MeshComp) const
	{
		return bUseActorAsExtraActor ? MeshComp.Owner : nullptr;
	}

	UFoghornDialogueDataAsset GetDialogueDataAsset() const
	{
		return DialogueAsset;
	}
}