import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBoss;

UCLASS(NotBlueprintable, meta = ("VacuumBossSlam (time marker)"))
class UAnimNotify_VacuumBossSlam : UAnimNotify 
{
	UPROPERTY()
	bool bLeft = true;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "VacuumBossSlam (time marker)";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		AVacuumBoss VacuumBoss = Cast<AVacuumBoss>(MeshComp.GetOwner());	
		if(VacuumBoss != nullptr)
		{
			VacuumBoss.TriggerSlamAttack(bLeft);
			return true;
		}

		return false;
	}
};