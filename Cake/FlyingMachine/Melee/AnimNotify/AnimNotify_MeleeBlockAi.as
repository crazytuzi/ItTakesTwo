import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;

UCLASS(NotBlueprintable)
class UAnimNotify_MeleeBlockAi : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "MeleeBlockAi";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AHazeCharacter Owner = Cast<AHazeCharacter>(MeshComp.GetOwner());	
		if(Owner != nullptr)
		{
			auto MeleeComp = UFlyingMachineMeleeSquirrelComponent::Get(Owner);
			if(MeleeComp != nullptr)
			{
				MeleeComp.bAiBlockedByNotify = true;
			}
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		AHazeCharacter Owner = Cast<AHazeCharacter>(MeshComp.GetOwner());	
		if(Owner != nullptr)
		{
			auto MeleeComp = UFlyingMachineMeleeSquirrelComponent::Get(Owner);
			if(MeleeComp != nullptr)
			{
				MeleeComp.bAiBlockedByNotify = false;
			}
		}
		return true;
	}
};