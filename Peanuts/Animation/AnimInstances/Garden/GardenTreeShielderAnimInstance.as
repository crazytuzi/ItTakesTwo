import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;
import Peanuts.Animation.Features.Garden.FeatureEnemyGardenTree;
// Imports
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Peanuts.Animation.AnimationStatics;



class UGardenTreeShielderAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FStructEnemyGardenTreeAnimations Animations;

	// Variables
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float SpeedX = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAttackingPlayer = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsChargingPlayer = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bStunned = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsAlive = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTookDamageThisTick = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsTakingDamage = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool IsBeeingHitBySickle = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float AngleToAttacker = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayingChargeAttackAnimation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayAdditiveShieldHitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayingHitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator DeathRotation;


	ASickleEnemy SickleEnemy;
	USickleEnemyGroundComponent AiGroundComp;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
		
		SickleEnemy = Cast<ASickleEnemy>(OwningActor);
		if (SickleEnemy == nullptr)
			return;
				
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{	
		// Valid check the Ground component
		if(AiGroundComp == nullptr)
		{
			AiGroundComp = USickleEnemyGroundComponent::Get(OwningActor);
			if(AiGroundComp == nullptr)
				return;
			Animations = AiGroundComp.AnimationFeature.Animations;
		}

		SpeedX = GetActorLocalVelocity(SickleEnemy).X;
		

		bAttackingPlayer = SickleEnemy.bAttackingPlayer;
		bIsChargingPlayer = bAttackingPlayer && GetAnimBoolParam(n"Charge");
		if (bIsChargingPlayer)
			bPlayingChargeAttackAnimation = true;

		bStunned = SickleEnemy.bIsBeeingHitByVine;
		
		IsBeeingHitBySickle = SickleEnemy.GetIsTakingDamage();
		bIsTakingDamage = IsBeeingHitBySickle && SickleEnemy.LastDamageAmount > 0;
		

		bTookDamageThisTick = GetAnimBoolParam(n"IsTakingDamage", true);
		if(bTookDamageThisTick)
		{
			// Enemy took damage this tick
			AngleToAttacker = SickleEnemy.GetAngleToAttacker();
			bIsAlive = SickleEnemy.IsAlive();
			if (!bIsAlive)
				DeathRotation.Yaw = AngleToAttacker;

			bPlayAdditiveShieldHitReaction = true;
			bPlayingHitReaction = true;
		}

		//IsBreakingOutOfVine = GetAnimBoolParam(n"ForceVineRelease", true);
		

	}

	UFUNCTION()
	void StopPlayingAdditiveHitReaction()
	{
		bPlayAdditiveShieldHitReaction = false;
	}

	UFUNCTION()
	void ExitHitReactionState()
	
	{
		bPlayingHitReaction = true;
	}

	UFUNCTION()
	void ChargeAttackStopped()
	{
		bPlayingChargeAttackAnimation = false;
	}

	UFUNCTION()
	void SetMovementBlocked(bool bStatus)
	{
		if(bStatus)
		{
			SickleEnemy.BlockAttackWithInstigator(this);

		}
		else
		{
			SickleEnemy.UnblockAttackWithInstigator(this);
			SickleEnemy.BlockMovement(0.3f);
		}
	}

	UFUNCTION()
	void SetAttackBlocked(bool bStatus)
	{
		if(bStatus)
		{
			SickleEnemy.BlockAttackWithInstigator(this);
		}
		else
		{
			SickleEnemy.UnblockAttackWithInstigator(this);
			SickleEnemy.BlockAttack(0.3f);
		}
	}

}