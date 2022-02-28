import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonBoss;
import Peanuts.Foghorn.FoghornStatics;

class UMoonBaboonAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData Mh;

	// Laser
	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData ActivateLaser;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData LaserHitPod;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData KnockedDownMh;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData CodyPickupUFO;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData CodyHoldingUFO;

	// Rockets
	UPROPERTY(Category = "Animations Rocket")
	FHazePlaySequenceData RocketHitReaction;

	UPROPERTY(Category = "Animations Rocket")
	FHazePlaySequenceData FireRocket;

	// Slam
	UPROPERTY(Category = "Animations Slam")
    FHazePlaySequenceData SlamAttack;
	

	// Variables
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bBossStunned;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	EMoonBaboonAttackMode CurrentAttackMode;
	
	UPROPERTY()
	bool bEnableLookAt;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector LookAtLocation;


	// Laser
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsLaserActiveChanged;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsLaserActive;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bCodyPickupUFO;

	UPROPERTY()
	bool bPrepareLaserPointer;


	// Rockets
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bHitByRocketThisTick;

	UPROPERTY()
	bool bFireRocket;


	// Slam
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlaySlamAttack;

	// Voiceover
	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset CoresDestroyedIdle;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset CoresDestroyedPickup;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset RocketFiredInitial;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset RocketFired;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset HitReactionMedium;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset HitReactionHeavy;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset HatchOpenIdle;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset VOSlamAttack;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset RocketTauntBarks;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset SlamTauntBarks;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset RoarEfforts;


	AMoonBaboonBoss MoonBaboonBoss;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		MoonBaboonBoss = Cast<AMoonBaboonBoss>(OwningActor.AttachParentActor);
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		// Valid check the actor
		if(MoonBaboonBoss == nullptr)
			return;

		// General
		bBossStunned = MoonBaboonBoss.bBossStunned;
		CurrentAttackMode = MoonBaboonBoss.CurrentAttackMode;

		if (CurrentAttackMode == EMoonBaboonAttackMode::LaserPointer)
		{
			if (GetAnimBoolParam(n"PrepareLaserPointer", true))
			{
				System::SetTimer(this, n"PlayPrepareForLaserPointer", 3.0f, false);	
			}

			bIsLaserActiveChanged = bIsLaserActive != MoonBaboonBoss.bLaserActive;
			bIsLaserActive = MoonBaboonBoss.bLaserActive;
			if (bIsLaserActiveChanged)
			{
				bPrepareLaserPointer = false;
			}

			bCodyPickupUFO = GetAnimBoolParam(n"CodyPickupUFO", true);
			
		}

		else if (CurrentAttackMode == EMoonBaboonAttackMode::Rockets)
		{
			if (GetAnimBoolParam(n"PrepareFireRocketLeft", true))
			{
				System::SetTimer(this, n"PlayPrepareForFireRocketLeft", 1.4f, false);	
			}
			if (GetAnimBoolParam(n"PrepareFireRocketRight", true))
			{
				System::SetTimer(this, n"PlayPrepareForFireRocketRight", 1.4f, false);	
			}

			bHitByRocketThisTick = GetAnimBoolParam(n"HitByRocket", true);
			
		}

		else if (CurrentAttackMode == EMoonBaboonAttackMode::Slam)
		{
			bPlaySlamAttack = GetAnimBoolParam(n"PlaySlam", true);
		}

		if (bEnableLookAt)
		{
			const FVector MoonBaboonLocation = OwningActor.GetActorLocation();
			LookAtLocation = FMath::VInterpTo(LookAtLocation, GetClosestActorLocation(MoonBaboonLocation), DeltaTime, 10.0f);
		}
	}

	UFUNCTION()
	void PlayPrepareForLaserPointer()
	{
		bPrepareLaserPointer = true;
	}

	UFUNCTION()
	void PlayPrepareForFireRocketLeft()
	{
		bFireRocket = true;
	}

	UFUNCTION()
	void PlayPrepareForFireRocketRight()
	{
		bFireRocket = true;
	}

	// Get the closest actor between May & Cody and return their world location
	UFUNCTION()
	FVector GetClosestActorLocation(FVector Location)
	{
		const AHazePlayerCharacter May = Game::GetMay();
		const AHazePlayerCharacter Cody = Game::GetCody();
		if (May == nullptr || Cody == nullptr)
			return FVector::ZeroVector;
		const FVector MayLocation = May.GetActorLocation();
		const FVector CodyLocation = Cody.GetActorLocation();

		if ((Location - MayLocation).Size() > (Location - CodyLocation).Size())
			return CodyLocation;

		return MayLocation;
	}

}