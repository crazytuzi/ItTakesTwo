import Peanuts.Foghorn.AnimNotify_FoghornBase;
import Peanuts.Foghorn.FoghornStatics;

UCLASS(NotBlueprintable, meta = ("FoghornEffort"))
class AnimNotify_FoghornEffort : AnimNotify_FoghornBase
{
	UPROPERTY(EditAnywhere, Category = "Parameters")
	UFoghornBarkDataAsset BarkAsset;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FoghornEffort";
	}

	void Play(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		PlayFoghornEffort(BarkAsset, GetActorOverride(MeshComp));
	}

	UFoghornBarkDataAsset GetBarkDataAsset() const
	{
		return BarkAsset;
	}
}