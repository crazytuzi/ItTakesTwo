import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;

// This will attach the player if it collides with the bullimpacts
UCLASS(NotBlueprintable, meta = ("ClockworkBullBossTriggerActionEvent"))
class UAnimNotify_ClockworkBullBossTriggerActionEvent : UAnimNotify
{
	UPROPERTY()
	EBullBossEventTags EventType = EBullBossEventTags::MAX;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "ClockworkBullBossTriggerActionEvent";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			Bull.TriggerActionEvent(EventType);
			return true;
		}

		return false;
	}


	


};