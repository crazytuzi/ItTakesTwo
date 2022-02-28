import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;

enum EAnimNotify_ClockworkBullBossSetTargetType
{
	// Clear the target
	None,

	// Locks the current one
	Current,

	// Force Cody
	Cody,

	// Force May
	May,

	// The closest one
	Closest,

	// Anyone valid
	Random,

	// If we can see anyone, set to that
	Visible,
}

// This will setup the current target for the bullboss. Or change it. It will also lock the bullboss in the attackstate
UCLASS(NotBlueprintable, meta = ("BullBossSetTarget"))
class UAnimNotify_ClockworkBullBossSetTarget : UAnimNotifyState
{
	// Target type to change to
	UPROPERTY()
	EAnimNotify_ClockworkBullBossSetTargetType TargetType = EAnimNotify_ClockworkBullBossSetTargetType::Current;

	// -1, the default attack angle (In degrees)
    UPROPERTY(meta = (EditCondition="TargetType == EAnimNotify_ClockworkBullBossSetTargetType::Visible", EditConditionHides))
    float VisibleAngle = -1.f;

	/* Locks the current target type
	 * The target is locked during the notify length, + the bonus time
	*/
	UPROPERTY()
	float LockedBonusTime = 0;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BullBossSetTarget";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{	
			if(TargetType == EAnimNotify_ClockworkBullBossSetTargetType::None)
			{
				Bull.ClearCurrentTargetFromControl();		
			}
			else if(TargetType == EAnimNotify_ClockworkBullBossSetTargetType::Cody)
			{
				if(Bull.CanTargetPlayer(Game::GetCody(), false))
					Bull.SetPlayerTargetFromControl(Game::GetCody());
			}
			else if(TargetType == EAnimNotify_ClockworkBullBossSetTargetType::May)
			{
				if(Bull.CanTargetPlayer(Game::GetMay(), false))
					Bull.SetPlayerTargetFromControl(Game::GetMay());
			}
			else if(TargetType == EAnimNotify_ClockworkBullBossSetTargetType::Random)
			{
				auto NewTarget = Bull.GetRandomPlayerTarget();
				if(NewTarget != nullptr)
					Bull.SetPlayerTargetFromControl(NewTarget);
			}
			else if(TargetType == EAnimNotify_ClockworkBullBossSetTargetType::Closest)
			{
				auto NewTarget = Bull.GetBestPlayerTarget();
				if(NewTarget != nullptr)
					Bull.SetPlayerTargetFromControl(NewTarget);
			}
			else if(TargetType == EAnimNotify_ClockworkBullBossSetTargetType::Visible)
			{
				FHazeIntersectionCone Cone;
				Bull.GetAttackIntersectionCone(Cone);
				if(VisibleAngle >= 0)
					Cone.AngleDegrees = VisibleAngle;

				AHazePlayerCharacter FoundTarget = Bull.GetBestVisiblePlayerTarget(Cone);
				if(FoundTarget != nullptr)
					Bull.SetPlayerTargetFromControl(FoundTarget);
			}

			if(Bull.CanChangeTarget())
				Bull.BlockChangeTargetTimeLeft = -1;
		}

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			if(Bull.BlockChangeTargetTimeLeft >= 0.f)
				Bull.BlockChangeTargetTimeLeft = FMath::Max(Bull.BlockChangeTargetTimeLeft, LockedBonusTime);
			else
				Bull.BlockChangeTargetTimeLeft = LockedBonusTime;
		}

		return true;
	}
};