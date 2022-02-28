import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Peanuts.Animation.AnimationStatics;

class UGardenTreeCopterAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Born;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData EnterBombRun;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData BombRunChase;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Attack01;

	UPROPERTY(Category = "Animations")
	FHazePlayRndSequenceData HitReaction;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Death;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData VineDeath;


	// Variables
	ASickleEnemy SickleEnemy;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsBombRunActive = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDropBomb = false;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTookDamageThisTick = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayHitReaction = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsAlive = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator LeafRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator AngleToAttacker;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsTakingSickleDamage;


	float PropellerRotationSpeed;

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (OwningActor == nullptr)
			return;

		SickleEnemy = Cast<ASickleEnemy>(OwningActor);
	}
	

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SickleEnemy == nullptr)
			return;
			
		bIsBombRunActive = SickleEnemy.bAttackingPlayer;
		if (bIsBombRunActive)
		{
			bIsBombRunActive = true;
			bDropBomb = GetAnimBoolParam(n"DropBomb", true);
			PropellerRotationSpeed = 850.f;
		}
		else
		{
			PropellerRotationSpeed = 650.f;
		}

		bTookDamageThisTick = GetAnimBoolParam(n"IsTakingDamage", true);
		if (bTookDamageThisTick)
		{
			// Enemy took damage this tick
			bPlayHitReaction = true;
			bIsBombRunActive = false;
			bIsTakingSickleDamage = SickleEnemy.bIsTakingSickleDamage;
			bIsAlive = SickleEnemy.IsAlive();
			AngleToAttacker.Yaw = SickleEnemy.GetAngleToAttacker();
		}

		// Calculate leaf rotation
		LeafRotation.Yaw = Math::FWrap(LeafRotation.Yaw + (DeltaTime * -PropellerRotationSpeed), 0.f, 360.f);

	}


	UFUNCTION()
	void StopPlayingHitReaction()
	{
		bPlayHitReaction = false;
	}

}