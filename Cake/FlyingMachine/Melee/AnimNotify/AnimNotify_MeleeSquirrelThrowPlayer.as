import Cake.FlyingMachine.Melee.MeleeTags;

UCLASS(NotBlueprintable, meta = ("Throw Player"))
class UAnimNotify_MeleeSquirrelThrowPlayer : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Throw Player";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AHazeCharacter Owner = Cast<AHazeCharacter>(MeshComp.GetOwner());	
		if(Owner != nullptr)
		{
			UHazeMelee2DComponent MeleeComp = UHazeMelee2DComponent::Get(Owner);
			if(MeleeComp != nullptr)
			{
				Owner.SetCapabilityActionState(MeleeTags::MeleeThrow, EHazeActionState::Active);

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
			UHazeMelee2DComponent MeleeComp = UHazeMelee2DComponent::Get(Owner);
			if(MeleeComp != nullptr)
			{
				Owner.SetCapabilityActionState(MeleeTags::MeleeThrow, EHazeActionState::Inactive);
			}
		}
		return true;
	}
};