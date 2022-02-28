import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;
import Peanuts.Animation.Features.Garden.FeatureEnemyGardenTree;
// Imports
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Peanuts.Animation.AnimationStatics;



class UGardenTreeBasicAnimInstance : UHazeAnimInstanceBase
{
	default SetRootMotionMode(ERootMotionMode::NoRootMotionExtraction);

	// Animations
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FStructEnemyGardenTreeAnimations Animations;

	// Variables
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float SpeedX = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAttackingPlayer = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsAlive = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTookDamageThisTick = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float AngleToAttacker = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator DeathRotation = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bExitHitReaction = true;


	ASickleEnemy SickleEnemy;
	USickleEnemyGroundComponent AiGroundComp;
	bool bHasEnabledRootMotion = false;

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
		if(SickleEnemy == nullptr)
			return;

		if(!SickleEnemy.IsEnemyValid())
			return;

		if(!SickleEnemy.IsAlive() && !bHasEnabledRootMotion)
		{
			bHasEnabledRootMotion = true;
			SetRootMotionMode(ERootMotionMode::RootMotionFromEverything);
		}

		// Valid check the Ground component
		if(AiGroundComp == nullptr)
		{
			AiGroundComp = USickleEnemyGroundComponent::Get(OwningActor);
			if(AiGroundComp == nullptr)
				return;
			Animations = AiGroundComp.AnimationFeature.Animations;
		}

		SpeedX = GetActorLocalVelocity(SickleEnemy).X;
		
		bAttackingPlayer = SickleEnemy.bAttackingPlayer && bExitHitReaction;
		
		bTookDamageThisTick = GetAnimBoolParam(n"IsTakingDamage", true);
		if(bTookDamageThisTick)
		{
			// Enemy took damage this tick
			AngleToAttacker = SickleEnemy.GetAngleToAttacker();
			bIsAlive = SickleEnemy.IsAlive();
			if (!bIsAlive)
				DeathRotation.Yaw = AngleToAttacker;
				
			bExitHitReaction = false;
		}
		

	}

	UFUNCTION()
	void ExitHitReactionState()
	{
		bExitHitReaction = true;
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
			SickleEnemy.UnblockAttackWithInstigator(this, 0.3f);
		}
	}

}