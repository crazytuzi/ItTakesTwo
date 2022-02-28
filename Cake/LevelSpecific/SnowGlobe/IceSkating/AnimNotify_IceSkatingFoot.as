import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;

UCLASS(NotBlueprintable, meta = ("IceSkatingFoot (time marker)"))
class UAnimNotify_IceSkatingFoot : UAnimNotify
{
	UPROPERTY(Category = "IceSkating")
	bool bRightFoot = false;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "IceSkatingFoot (time marker)";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (MeshComp.GetOwner() == nullptr)
			return true;

		auto SkateComp = UIceSkatingComponent::Get(MeshComp.GetOwner());
		if (SkateComp == nullptr)
			return true;

		SkateComp.bAnimRightFoot = bRightFoot;
		return true;
	}
}