import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Animation.FishAnimationComponent;

UCLASS(NotBlueprintable)
class UAnimNotify_AnglerFishLunge : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AnglerFishLunge";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		return true;
	}
};