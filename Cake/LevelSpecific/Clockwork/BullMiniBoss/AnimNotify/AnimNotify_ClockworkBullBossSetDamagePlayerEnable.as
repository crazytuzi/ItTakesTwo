import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;


// This will make the bullboss not rotate using code, towards the current target location
UCLASS(NotBlueprintable, meta = ("BullBossSetDamagePlayerEnable"))
class UAnimNotify_ClockworkBullBossSetDamagePlayerEnable : UAnimNotifyState
{
	UPROPERTY()
	EBullBossDamageInstigatorType DamageInstigator = EBullBossDamageInstigatorType::Head;

	UPROPERTY()
	EBullBossDamageType DamageType = EBullBossDamageType::MovementDirectionForce;

	// The force the player will be thrown with
	UPROPERTY()
	FVector ImpactForceLocalSpace = FVector::ZeroVector;

	// Random factor calculated between this and 'ImpactForceLocalSpaceRandomOffsetMax'
	UPROPERTY()
	FVector ImpactForceLocalSpaceRandomOffsetMin = FVector::ZeroVector;

	// Random factor calculated between 'ImpactForceLocalSpaceRandomOffsetMin' and this
	UPROPERTY()
	FVector ImpactForceLocalSpaceRandomOffsetMax = FVector::ZeroVector;

	/* If zero, the force is used as a oneoff velocity
	 * If time is used, then the force will be used as a delta until the apply force time is out.
	*/
	UPROPERTY()
	float ApplyForceTime = 0;

	/* If -1 is used, the take damage will be requested until the player is grounded. */ 
	UPROPERTY()
	float LockedIntoAttackTime = -1;

	UPROPERTY()
	float BonusRadius = 0;

	UPROPERTY()
	float BonusHeight = 0;

	UPROPERTY()
	EBullBossDamageAmountType DamageAmountType = EBullBossDamageAmountType::Medium;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BullBossSetDamagePlayerEnable";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			FVector FinalFore = ImpactForceLocalSpace;
			FinalFore.X += FMath::RandRange(ImpactForceLocalSpaceRandomOffsetMin.X, ImpactForceLocalSpaceRandomOffsetMax.X);
			FinalFore.Y += FMath::RandRange(ImpactForceLocalSpaceRandomOffsetMin.Y, ImpactForceLocalSpaceRandomOffsetMax.Y);
			FinalFore.Z += FMath::RandRange(ImpactForceLocalSpaceRandomOffsetMin.Z, ImpactForceLocalSpaceRandomOffsetMax.Z);
			Bull.SetDamageEnabled(DamageInstigator, DamageType, DamageAmountType, ApplyForceTime, FinalFore, LockedIntoAttackTime, FVector2D(BonusRadius, BonusHeight));
		}
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			Bull.SetDamageDisabled(DamageInstigator);
		}
		return true;
	}
};