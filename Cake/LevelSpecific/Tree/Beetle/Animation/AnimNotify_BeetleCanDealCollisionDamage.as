import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimationComponent;

UCLASS(NotBlueprintable)
class UAnimNotify_BeetleCanDealCollisionDamage : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BeetleDoCollisionDamage";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AActor Beetle = MeshComp.Owner;
		if (Beetle == nullptr)
			return false;
		
		UBeetleAnimationComponent AnimComp = UBeetleAnimationComponent::Get(Beetle);
		if (AnimComp == nullptr)
			return false;
		
		AnimComp.DealCollisionDamageBegin();
		return true;
	}


	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		AActor Beetle = MeshComp.Owner;
		if (Beetle == nullptr)
			return false;
		
		UBeetleAnimationComponent AnimComp = UBeetleAnimationComponent::Get(Beetle);
		if (AnimComp == nullptr)
			return false;
		
		AnimComp.DealCollisionDamageEnd();
		return true;
	}
};