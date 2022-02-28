import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;

class UHazePlayerTakeDamageFromBullBullsFeatureSubAnimInstance : UHazeFeatureSubAnimInstance
{
	UPROPERTY()
	AHazePlayerCharacter PlayerOwner;

	UPROPERTY()
	UClockWorkBullBossPlayerComponent BullBossComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(GetOwningActor());
		if(PlayerOwner != nullptr)
		{
			UClockWorkBullBossPlayerComponent::Get(PlayerOwner);
		}
	}

	UFUNCTION(BlueprintPure)
	EBullBossDamageInstigatorType GetAnimDamageInstigatorType()
	{
		if(BullBossComponent == nullptr)
			return EBullBossDamageInstigatorType::None;
		
		if(!BullBossComponent.bIsTakingDamageFromBoss)
			return EBullBossDamageInstigatorType::None;	
		
		return BullBossComponent.ActiveDamage.DamageInstigator;
	}

	UFUNCTION(BlueprintPure)
	EBullBossDamageType GetAnimBossDamageType()
	{
		if(BullBossComponent == nullptr)
			return EBullBossDamageType::MovementDirectionForce;
		
		if(!BullBossComponent.bIsTakingDamageFromBoss)
			return EBullBossDamageType::MovementDirectionForce;	

		return BullBossComponent.ActiveDamage.DamageType;
	}

	UFUNCTION()
	void SetStunnedEnabled()
	{
		if(PlayerOwner != nullptr)
			PlayerOwner.SetCapabilityActionState(ClockworkBullBossTags::ClockworkBullBossStunned, EHazeActionState::Active);
	}

	UFUNCTION()
	void SetStunnedDisabled()
	{
		if(PlayerOwner != nullptr)
			PlayerOwner.SetCapabilityActionState(ClockworkBullBossTags::ClockworkBullBossStunned, EHazeActionState::Inactive);
	}

}

class UHazeBullBossChargeFeatureSubAnimInstance : UHazeFeatureSubAnimInstance
{
	
}

void FillAttackReplicationData(FBullBossAttackReplicationParams& RepData, AClockworkBullBoss BullOwner, AHazePlayerCharacter Target)
{
	RepData.RandomAttack = FMath::RandRange(0, 3);
	RepData.RandomAttack2 = FMath::RandRange(0, 3);
	RepData.RandomAttack3 = FMath::RandRange(0, 3);

	const float DistanceToTarget = BullOwner.GetDistanceTo(Target);
	
	if(DistanceToTarget <= 800)
		RepData.DistanceToTargetType = EBullBossAnimationDistance::Close;
	else if(DistanceToTarget <= 1300)
		RepData.DistanceToTargetType = EBullBossAnimationDistance::MediumClose;
	else
		RepData.DistanceToTargetType = EBullBossAnimationDistance::Far;

	if(DistanceToTarget > 40)
	{
		const FVector WantedFacingDirection = (Target.GetActorLocation() - BullOwner.GetActorLocation()).GetSafeNormal();
		const float WantedFacingRotationFullAngleDiff = Math::GetAngle(BullOwner.GetActorForwardVector(), WantedFacingDirection);
		const float RightDot = WantedFacingDirection.DotProduct(BullOwner.GetActorRightVector());
		if (RightDot > 0)
			RepData.AnimationVariation = EHazeAnimationDirectionDiffType::ToTheRight;
		else if (RightDot < 0)
			RepData.AnimationVariation = EHazeAnimationDirectionDiffType::ToTheLeft;
		else
			RepData.AnimationVariation = EHazeAnimationDirectionDiffType::None;
	}
}	

class UHazeBullBossAttackFeatureSubAnimInstance : UHazeFeatureSubAnimInstance
{
	UPROPERTY()
	AClockworkBullBoss BullBoss;

	UPROPERTY()
	FBullBossAttackReplicationParams ReplicationParams;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		BullBoss = Cast<AClockworkBullBoss>(OwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(BullBoss != nullptr)
		{
			ReplicationParams = BullBoss.AttackReplicationParams;
		}
	}

	UFUNCTION(BlueprintPure)
	EBullBossAnimationDistance GeAnimationDistance() const
	{
		const float DistanceToTarget = BullBoss.GetDistanceTo(BullBoss.GetCurrentTargetPlayer());
		
		if(DistanceToTarget <= 800)
			return EBullBossAnimationDistance::Close;
		else if(DistanceToTarget <= 1300)
			return EBullBossAnimationDistance::MediumClose;
		else
			return EBullBossAnimationDistance::Far;
	}

	
	UFUNCTION(BlueprintPure)
	EHazeAnimationDirectionDiffType GetAnimationDirection() const
	{
		AHazePlayerCharacter Target = BullBoss.GetCurrentTargetPlayer();
		const float DistanceToTarget = BullBoss.GetDistanceTo(Target);
		if(DistanceToTarget > 40)
		{
			const FVector WantedFacingDirection = (Target.GetActorLocation() - BullBoss.GetActorLocation()).GetSafeNormal();
			const float WantedFacingRotationFullAngleDiff = Math::GetAngle(BullBoss.GetActorForwardVector(), WantedFacingDirection);
			const float RightDot = WantedFacingDirection.DotProduct(BullBoss.GetActorRightVector());
			if (RightDot > 0)
				return EHazeAnimationDirectionDiffType::ToTheRight;
			else if (RightDot < 0)
				return EHazeAnimationDirectionDiffType::ToTheLeft;

		}
		return EHazeAnimationDirectionDiffType::None;
	}

}
