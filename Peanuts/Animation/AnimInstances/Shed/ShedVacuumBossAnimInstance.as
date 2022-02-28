// Imports
import Peanuts.Animation.AnimationStatics;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBoss;

class UShedVacuumBossAnimInstance : UHazeAnimInstanceBase
{

	// Animations

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData BombsMh;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData BombsFireLeft;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData BombsFireRight;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DoubleSlam;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DebrisMh;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DebrisFire;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData DebrisAdditive;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Slam;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Minefield;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData StunnedEnter;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Stunned;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Death;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData EndArmOveride;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData EyesPoppedOutEnter;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData EyesPoppedOut;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData AdditiveHitReactions;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Additive;

	//VO Barks & Efforts
	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset ThrowExplosives;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset ThrowMines;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset ThrowDebris;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset ThrowDebrisSlam;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset ShortSlam;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset LongSlam;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset HitReactionTaunt;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset HitReactionMedium;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset HitReactionHeavy;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset EndingIdle;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset GenericTaunt;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset EffortCough;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset EffortAttackHeavy;


	AVacuumBoss VacuumBoss;
	AHazePlayerCharacter MayPlayerCharacter;
	AHazePlayerCharacter CodyPlayerCharacter;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EVacuumBossAttackMode CurrentAttackMode;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector MayWorldLocation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector CodyWorldLocation;

	UPROPERTY()
	bool bEnableLookAt = true;

	// The alpha of the physics played on top of the base animation
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PhysicsAlpha = 0.2f;


	// Bomb Mode

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float BombsAimValueZ;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFiriedBombThisTickLeft;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFiriedBombThisTickRight;

	UPROPERTY()
	bool bPlayFireBombLeft = false;

	UPROPERTY()
	bool bPlayFireBombRight = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitByBombThisTick = false;
	UPROPERTY()
	bool bPlayHitReaction = false;

	UPROPERTY()
	float NumberOfHits = 0.0f;


	// Debris Mode
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFireDebrisThisTick = false;

	UPROPERTY()
	bool bPlayFireDebrisAdditive = false;

	// Minefield Mode
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAllMinefieldsLaunched = false;


	// Ending

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bStunned;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float EndLeftArmOverrideVal = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float EndLeftArmOverrideSideVal = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float EndRightArmOverrideVal = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float EndRightArmOverrideSideVal = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float EndAverageArmOverrideVal = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsDead = false;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
		
		VacuumBoss = Cast<AVacuumBoss>(OwningActor);
		BombsAimValueZ = OwningActor.ActorLocation.Z + 2500;

		// Delay getting May / Cody since they are not valid the first tick.
		System::SetTimer(this, n"GetMayAndCody", 0.1f, false);

	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (VacuumBoss == nullptr)
			return;

		CurrentAttackMode = VacuumBoss.CurrentAttackMode;

		// Bomb Mode
		bFiriedBombThisTickLeft = GetAnimBoolParam(n"FireBombLeft", true);
		if (bFiriedBombThisTickLeft)
		{
			bPlayFireBombLeft = true;
		}
		bFiriedBombThisTickRight = GetAnimBoolParam(n"FireBombRight", true);
		if (bFiriedBombThisTickRight)
		{
			bPlayFireBombRight = true;
		}

		bHitByBombThisTick = GetAnimBoolParam(n"HitByBomb", true);
		if (bHitByBombThisTick)
		{
			bPlayHitReaction = true;
			NumberOfHits += 1.0f;
			bEnableLookAt = false;
		}
		else if (bPlayHitReaction)
		{
			NumberOfHits -= DeltaTime * 2;
		}

		// Debris Mode
		bFireDebrisThisTick = GetAnimBoolParam(n"FireDebris", true);
		if (bFireDebrisThisTick)
		{
			bPlayFireDebrisAdditive = true;
		}

		// Minefield Mode
		bAllMinefieldsLaunched = VacuumBoss.bAllMinefieldsLaunched;

		// Ending
		bStunned = VacuumBoss.bStunned;
		if (bStunned) 
		{
			EndLeftArmOverrideVal = GetAnimFloatParam(n"LeftArmOverride", true);
			EndRightArmOverrideVal = GetAnimFloatParam(n"RightArmOverride", true);
			EndAverageArmOverrideVal = (EndLeftArmOverrideVal + EndRightArmOverrideVal) / 2;
			if (EndAverageArmOverrideVal== 1)
			{
				bIsDead = false;
			}
		}
		

		// Get the alpha from the float param which is set through animNotifies in the animations.
		const float PhysicsAlphaInterpSpeed = GetAnimFloatParam(n"PhysicsAlpaInterp");
		if (PhysicsAlphaInterpSpeed != 0.f)
			PhysicsAlpha = FMath::FInterpTo(PhysicsAlpha, GetAnimFloatParam(n"PhysicsAlpa"), DeltaTime, PhysicsAlphaInterpSpeed);
		else
			PhysicsAlpha = GetAnimFloatParam(n"PhysicsAlpa");


		// Get the world location of May & Cody, used for Look At & Aim
		if (MayPlayerCharacter != nullptr) 
		{
			MayWorldLocation = MayPlayerCharacter.ActorLocation;
			CodyWorldLocation = CodyPlayerCharacter.ActorLocation;
		}

	}


	// Get a reference to May & Cody
	UFUNCTION()
	void GetMayAndCody()
	{
		Game::GetMayCody(MayPlayerCharacter, CodyPlayerCharacter);
	}	

}