
// Imports
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Peanuts.Animation.AnimationStatics;

class UGardenTreeCopterMotherAnimInstance : UHazeAnimInstanceBase
{

	// Animations

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Spawn;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData GiveBirth;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData GiveBirthUnTouchable;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData VineSlingCatch;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData VineSlingStunned;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData VineSlingStunnedExit;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData VineSlingHitReaction;

	UPROPERTY(Category = "Animations")
	FHazePlayRndSequenceData HitReaction;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DeathFwd;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DeathBck;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DeathLeft;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DeathRight;

	// Variables
	ASickleEnemy SickleEnemy;
	
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData DeathAnim;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayGiveBirthUntouchableAnim;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator LeafRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float AngleToAttacker;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTookDamageThisTick = false;

	UPROPERTY()
	bool bPlayHitReaction = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsAlive = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bVineCatch;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bLanded;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGiveBirth;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayGivingBirthAdditive;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGiveBirthUntochable;


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

		bVineCatch = SickleEnemy.bIsBeeingHitByVine;
		if (bVineCatch)
		{
			bGiveBirthUntochable = true;
			bLanded = GetAnimBoolParam(n"Landed", true);
			LeafRotation.Yaw = 180.f;
			//VineHoldReleased = GetAnimFloatParam(n"VineHoldReleased", true);
		} 
		else
		{
			bGiveBirth = GetAnimBoolParam(n"GaveBirth", true);
			if (bGiveBirth)
			{
				//PrintToScreenScaled("bGiveBirth: " + bGiveBirth, 10.f, Scale = 3.f);
				bPlayGivingBirthAdditive = true;
				PickGiveBirthAnim();
			}
			
		}

		// Hit reactions
		bTookDamageThisTick = GetAnimBoolParam(n"IsTakingDamage", true);
		if (bTookDamageThisTick)
		{
			// Enemy took damage this tick
			bIsAlive = SickleEnemy.IsAlive();
			AngleToAttacker = SickleEnemy.GetAngleToAttacker();
			bPlayHitReaction = true;
			if (!bIsAlive)
			{
				if (AngleToAttacker < 45.f || AngleToAttacker > 315.f)
					DeathAnim = DeathFwd;
				else if (AngleToAttacker > 225.f)
					DeathAnim = DeathLeft;
				else if (AngleToAttacker > 135.f)
					DeathAnim = DeathBck;
				else
					DeathAnim = DeathRight;
			}
		}

		// Calculate leaf rotation
		LeafRotation.Yaw = Math::FWrap(LeafRotation.Yaw + (DeltaTime * -700.f), 0.f, 360.f);

	}

	UFUNCTION()
	void StopGivingBirth()
	{
		if (!bGiveBirth)
			bPlayGivingBirthAdditive = false;
	}

	UFUNCTION()
	void PickGiveBirthAnim()
	{
		if (bGiveBirthUntochable)
			bPlayGiveBirthUntouchableAnim = true;
		else
			bPlayGiveBirthUntouchableAnim = false;
	}

	UFUNCTION()
	void EnteredMhState()
	{
		bGiveBirthUntochable = false;
	}

}