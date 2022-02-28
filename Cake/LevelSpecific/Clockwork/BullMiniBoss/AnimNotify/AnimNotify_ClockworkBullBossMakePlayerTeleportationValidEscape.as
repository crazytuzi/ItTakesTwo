import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;

// This will make the bullboss not rotate using code, towards the current target location
UCLASS(NotBlueprintable, meta = ("BossMakePlayerTeleportationIsValidEscape"))
class UAnimNotify_ClockworkBullBossMakePlayerTeleportationValidEscape : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BossMakePlayerTeleportationIsValidEscape";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			Bull.SetValidEscapeWindowActive(true);
		}
		return true;
	}


	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			Bull.SetValidEscapeWindowActive(false);
		}
		return true;
	}
};