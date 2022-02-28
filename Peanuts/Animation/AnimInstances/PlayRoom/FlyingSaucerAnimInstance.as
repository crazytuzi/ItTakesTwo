import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonBoss;
import Peanuts.Animation.AnimationStatics;

class UFlyingSaucerAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData LaserMh;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData LaserHitPod;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData LaserKnockedDownMh;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData CodyPickupUfoEnter;

	UPROPERTY(Category = "Animations Laser")
    FHazePlayBlendSpaceData CodyPickupUfoMh;

	UPROPERTY(Category = "Animations Laser")
    FHazePlaySequenceData LaserRippedOff;


	UPROPERTY(Category = "Animations Rocket")
    FHazePlayBlendSpaceData FlyingMh; 

	UPROPERTY(Category = "Animations Rocket")
    FHazePlaySequenceData FireRocketLeftAdditive;

	UPROPERTY(Category = "Animations Rocket")
    FHazePlaySequenceData FireRocketRightAdditive;

	UPROPERTY(Category = "Animations Rocket")
    FHazePlayBlendSpaceData RocketHitReaction;

	UPROPERTY(Category = "Animations Rocket")
    FHazePlaySequenceData RocketKnockedDownMh;

	UPROPERTY(Category = "Animations Slam")
    FHazePlaySequenceData SlamAttack;

	

	// Variables
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bBossStunned;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector2D BlendspaceMovementInput;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	EMoonBaboonAttackMode CurrentAttackMode;


	// Laser
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsLaserActive;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector LaserImpactLocation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bCodyPickupUFO;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bLockLaserTransform;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector LockLaserLocaiton;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator LockLaserRotation;


	// Rockets
	UPROPERTY()
	bool bPlayFireRocketLeft;

	UPROPERTY()
	bool bPlayFireRocketRight;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bHitByRocketThisTick;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float RocketHitDirection;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bCodyEnteredUfo;

	// Slams
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlaySlamAttack;
	
	UPROPERTY(NotEditable, BlueprintReadOnly)
	float LiftingUFO;

	AMoonBaboonBoss MoonBaboonBoss;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		MoonBaboonBoss = Cast<AMoonBaboonBoss>(OwningActor);
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		
		// Valid check the actor
		if(MoonBaboonBoss == nullptr)
			return;
		
		// General
		bool bBossStunnedChanged = false;
		if (bBossStunned != MoonBaboonBoss.bBossStunned)
		{
			bBossStunnedChanged = true;
		}

		bBossStunned = MoonBaboonBoss.bBossStunned;
		CurrentAttackMode = MoonBaboonBoss.CurrentAttackMode;

		// Laser
		if (CurrentAttackMode == EMoonBaboonAttackMode::LaserPointer)
		{
			bIsLaserActive = MoonBaboonBoss.bLaserActive;
			LaserImpactLocation = MoonBaboonBoss.LaserImpactLocation;
			if (bBossStunned)
				bCodyPickupUFO = GetAnimBoolParam(n"CodyPickupUFO", true);
			LiftingUFO = GetAnimFloatParam(n"LiftingUFO", true);
		}


		// Rockets
		else if (CurrentAttackMode == EMoonBaboonAttackMode::Rockets)
		{
			if (bBossStunnedChanged && !bBossStunned)
			{
				LockLaserBaseTransform();
			}
			GetMoonBaboonLocalVelocity(DeltaTime);
			if (GetAnimBoolParam(n"FireRocketLeft", true))
			{
				bPlayFireRocketLeft = true;
			}
			if (GetAnimBoolParam(n"FireRocketRight", true))
			{
				bPlayFireRocketRight = true;
			}
	
			bHitByRocketThisTick = GetAnimBoolParam(n"HitByRocket", true);
			if (bHitByRocketThisTick)
			{
				RocketHitDirection = GetAnimFloatParam(n"RocketHitDirection", true);
			}

		}

		// Slam
		else if (CurrentAttackMode == EMoonBaboonAttackMode::Slam)
		{
			GetMoonBaboonLocalVelocity(DeltaTime);
			bPlaySlamAttack = GetAnimBoolParam(n"PlaySlam", true);
		}

	}

	// Calculate the local velocity of the UFO manually since GetActorVelocity isn't working
	FVector PreviousWorldLocation;
	UFUNCTION()
	void GetMoonBaboonLocalVelocity(float DeltaTime)
	{
		const FVector NewLocaiton = MoonBaboonBoss.GetActorLocation();
		const FVector DeltaVector = PreviousWorldLocation - NewLocaiton;
		const FVector ActorLocalVelocity = OwningActor.GetActorRotation().UnrotateVector(DeltaVector / DeltaTime);
		BlendspaceMovementInput.X = FMath::Clamp(ActorLocalVelocity.Y, -1500, 1500);
		BlendspaceMovementInput.Y = FMath::Clamp(ActorLocalVelocity.X, -1000, 1000);
		PreviousWorldLocation = NewLocaiton;
	}


	// Lock the laser world location / rotation (once ripped off the UFO)
	UFUNCTION()
	void LockLaserBaseTransform()
	{
		bLockLaserTransform = true;
		FTransform LaserBaseTransform = MoonBaboonBoss.UFOSkelMesh.GetSocketTransform(n"LaserBase");
		LockLaserRotation = LaserBaseTransform.GetRotation().Rotator();
		LockLaserLocaiton = LaserBaseTransform.Location;
	}

}