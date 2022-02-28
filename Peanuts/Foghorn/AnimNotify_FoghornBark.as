import Peanuts.Foghorn.AnimNotify_FoghornBase;
import Peanuts.Foghorn.FoghornStatics;

UCLASS(NotBlueprintable, meta = ("FoghornBark"))
class AnimNotify_FoghornBark : AnimNotify_FoghornBase
{
	UPROPERTY(EditAnywhere, Category = "Parameters")
	UFoghornBarkDataAsset BarkAsset;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FoghornBark";
	}

	void Play(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		PlayFoghornBark(BarkAsset, GetActorOverride(MeshComp));
	}

	UFoghornBarkDataAsset GetBarkDataAsset() const
	{
		return BarkAsset;
	}
}