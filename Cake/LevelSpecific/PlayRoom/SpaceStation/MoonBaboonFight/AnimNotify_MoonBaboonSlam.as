import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonBoss;

UCLASS(NotBlueprintable, meta = ("MoonBaboonSlam (time marker)"))
class UAnimNotify_MoonBaboonSlam : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "MoonBaboonSlam (time marker)";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		AMoonBaboonBoss MoonBaboon = Cast<AMoonBaboonBoss>(MeshComp.GetOwner());	
		if(MoonBaboon != nullptr)
		{
			MoonBaboon.SpawnSlamCircle();
			return true;
		}

		return false;
	}
};