// Imports
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Peanuts.Animation.AnimationStatics;

class UGardenTreeSproutAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData EnterUnderGround;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData UnderGroundMoveset;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData ExitUnderGround;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Attack01;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData HitReaction;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Death;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData VineHold;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData VineRelease;


	// Variables

	// Is enemy attacking player?
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAttackingPlayer = false;

	// True for one tick when the sickle hits the enemy
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTookDamageThisTick = false;

	// Is enemy alive
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsAlive = true;

	// Is character under ground
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsUnderGround = true;

	// Is Cody holding the enemy with VineSling
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bVineHolding = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayAdditiveHitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float BlendspaceValueX;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float AngleToAttacker;

	ASickleEnemy SickleEnemy;
	FRotator ActorRotation;

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{

		// Valid check the actor
		if (OwningActor == nullptr)
			return;
		
		SickleEnemy = Cast<ASickleEnemy>(OwningActor);
		bPlayAdditiveHitReaction = false;
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		
		// Valid check the SickleEnemy
		if(SickleEnemy == nullptr)
			return;

		const FRotator DeltaRotation = (ActorRotation - OwningActor.ActorRotation).Normalized;
		ActorRotation = OwningActor.ActorRotation;
		if (DeltaTime != 0.f)
			BlendspaceValueX = FMath::Clamp((-DeltaRotation.Yaw / DeltaTime) / 200.f, -1.f, 1.f);

		bIsUnderGround = !SickleEnemy.bAttackingPlayer;

		bVineHolding = SickleEnemy.bIsBeeingHitByVine;

		bAttackingPlayer = GetAnimBoolParam(n"Shoot", true);

		bTookDamageThisTick = GetAnimBoolParam(n"IsTakingDamage", true);
		if (bTookDamageThisTick)
		{
			// Enemy took damage this tick
			bIsAlive = SickleEnemy.IsAlive();
			bPlayAdditiveHitReaction = true;
			AngleToAttacker = SickleEnemy.GetAngleToAttacker();
		}

	}


	UFUNCTION()
	void StopPlayingHitReaction()
	{
		bPlayAdditiveHitReaction = false;
	}

}