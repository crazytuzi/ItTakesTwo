import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;

// This will change the current state to charging instead of targeting
UCLASS(NotBlueprintable, meta = ("BullBossStartedChargeAttack"))
class UAnimNotify_ClockworkBullBossStartedChargeAttack : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BullBossStartedChargeAttack";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			// This can never fail, for safety
			if(Bull.ChargeState == EBullBossChargeStateType::TargetingForward)
				Bull.ChangeChargeState(EBullBossChargeStateType::RushingForward);
			else 
				Bull.ChangeChargeState(EBullBossChargeStateType::RushingMay);
		}

		return true;
	}
};