

UCLASS(NotBlueprintable, meta = ("MeleeCanTriggerNextMove (time marker)"))
class UAnimNotify_MeleeCanTriggerNextMove : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "MeleeCanTriggerNextMove";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (MeshComp.GetOwner() == nullptr)
			return false; // Editor preview

		UHazeMelee2DComponent MeleeComp = UHazeMelee2DComponent::Get(MeshComp.GetOwner());
		if(MeleeComp != nullptr)
		{
			MeleeComp.UnblockActionInput();
			return true;
		}

		return false;
	}
};