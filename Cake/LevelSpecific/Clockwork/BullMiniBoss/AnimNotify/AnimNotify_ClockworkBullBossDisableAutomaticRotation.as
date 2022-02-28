import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;

// This will make the bullboss not rotate using code, towards the current target location
UCLASS(NotBlueprintable, meta = ("BullBossDisableAutomaticRotation"))
class UAnimNotify_ClockworkBullBossDisableAutomaticRotation : UAnimNotifyState
{
	UPROPERTY()
	float LerpInTime = 0;

	UPROPERTY()
	float LerpOutInitialDelayTime = 0;

	UPROPERTY()
	float LerpOutTime = 0;

	UPROPERTY()
	bool bUseCurve = false;

	UPROPERTY(meta = (EditCondition = "bUseCurve", EditConditionHides))
	FRuntimeFloatCurve RotationSpeedCurve;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BullBossDisableAutomaticRotation";
	}

	float CurrentDuration = 0;
	float MaxDuration = 0;

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{	
			if(bUseCurve)
			{
				Bull.SetAutomaticRotionCurve(RotationSpeedCurve, TotalDuration);
			}
			else
			{
				Bull.DectivateAutomaticRotation(FMath::Min(LerpInTime, TotalDuration));
			}
		}

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			Bull.ActivateAutomaticRotation(LerpOutTime, LerpOutInitialDelayTime);
		}
		return true;
	}
};