import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;


UCLASS(NotBlueprintable, meta = ("ShootNut"))
class UAnimNotify_MeleeSquirrelShootNut : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "ShootNut";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AHazeCharacter Owner = Cast<AHazeCharacter>(MeshComp.GetOwner());	
		if(Owner != nullptr)
		{
			UFlyingMachineMeleeSquirrelComponent MeleeComp = UFlyingMachineMeleeSquirrelComponent::Get(Owner);
			if(MeleeComp != nullptr)
			{
				Owner.SetCapabilityActionState(MeleeTags::MeleeActivateNut, EHazeActionState::ActiveForOneFrame);
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
				Owner.SetCapabilityActionState(MeleeTags::MeleeShootNut, EHazeActionState::ActiveForOneFrame);
			}
		}
		return true;
	}
};