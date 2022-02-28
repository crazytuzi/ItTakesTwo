import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimationComponent;

UCLASS(NotBlueprintable)
class UAnimNotify_BeetleLaunch : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BeetleLaunch";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		AActor Beetle = MeshComp.Owner;
		if (Beetle == nullptr)
			return false;
		
		UBeetleAnimationComponent AnimComp = UBeetleAnimationComponent::Get(Beetle);
		if (AnimComp == nullptr)
			return false;
		
		AnimComp.LaunchNotify();
		return true;
	}
}