import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;

// This will make the bullboss not rotate using code, towards the current target location
UCLASS(NotBlueprintable, meta = ("BullBossSetAttackRange"))
class UAnimNotify_ClockworkBullBossSetAttackRange : UAnimNotify
{
	UPROPERTY()
	FBullAttackRangeChange Settings;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BullBossSetAttackRange";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			Bull.AttackRangeChange = Settings;
			return true;
		}

		return false;
	}
};