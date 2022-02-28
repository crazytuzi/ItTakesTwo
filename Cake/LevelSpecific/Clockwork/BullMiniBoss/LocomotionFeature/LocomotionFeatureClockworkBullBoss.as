
// Default Movement
class ULocomotionFeatureClockworkBullBossMove : UHazeLocomotionFeatureBase
{
   default Tag = n"Movement";
    
    UPROPERTY(Category = "Locomotion")
    FHazePlayRndSequenceData Idle;
    
    UPROPERTY(Category = "Locomotion")
    FHazePlayRndSequenceData Walk;

	UPROPERTY(Category = "Locomotion")
    FHazePlayBlendSpaceData Run;

    UPROPERTY(Category = "Locomotion")
    FHazePlaySequenceData RunStart;

	UPROPERTY(Category = "Turns")
    FHazePlaySequenceData Turn90L;

	UPROPERTY(Category = "Turns")
    FHazePlaySequenceData Turn90R;

	UPROPERTY(Category = "Turns")
    FHazePlaySequenceData Turn180L;

	UPROPERTY(Category = "Turns")
    FHazePlaySequenceData Turn180R;

	UPROPERTY(Category = "Override")
    FHazePlaySequenceData TailOverride;
};

// Default Attack
class ULocomotionFeatureClockworkBullBossAttack : UHazeLocomotionFeatureBase
{
   default Tag = n"Attack";


   	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData StartMovement;

   	UPROPERTY(Category = "FirstAttack")
    FHazePlayRndSequenceData AttackAnticipation;

	UPROPERTY(Category = "FirstAttack")
    FHazePlaySequenceData AttackAnticipationVar2;

	UPROPERTY(Category = "FirstAttack")
    FHazePlaySequenceData AttackAnticipationShort;

	UPROPERTY(Category = "FirstAttack")
    FHazePlaySequenceData AttackAnticipationShorter;
    
    UPROPERTY(Category = "FirstAttack")
    FHazePlayRndSequenceData Attack1;

	UPROPERTY(Category = "FirstAttack")
    FHazePlaySequenceData Attack1Var2;

	UPROPERTY(Category = "FirstAttack")
    FHazePlaySequenceData Attack1Var3;

	UPROPERTY(Category = "FirstAttack")
    FHazePlaySequenceData Attack1Close;

	UPROPERTY(Category = "SecondAttack")
    FHazePlayRndSequenceData Attack2;

	UPROPERTY(Category = "SecondAttack")
    FHazePlayRndSequenceData Attack2Close;

	UPROPERTY(Category = "SecondAttack")
    FHazePlaySequenceData Attack2CloseVar2;

	UPROPERTY(Category = "ThirdAttack")
    FHazePlayRndSequenceData Attack3;

	UPROPERTY(Category = "GoToMovementAfterFirstAttack")
    FHazePlaySequenceData GoToMovement;

	UPROPERTY(Category = "GoToMovementAfterFirstAttack")
    FHazePlaySequenceData GoToMovementLeft;

	UPROPERTY(Category = "GoToMovementAfterFirstAttack")
    FHazePlaySequenceData GoToMovementRight;

	UPROPERTY(Category = "GoToMovementAfterSecondAttack")
    FHazePlaySequenceData GoToMovement2;

	UPROPERTY(Category = "GoToMovementAfterSecondAttack")
    FHazePlaySequenceData GoToMovement2Left;

	UPROPERTY(Category = "GoToMovementAfterSecondAttack")
    FHazePlaySequenceData GoToMovement2Right;

	UPROPERTY(Category = "ExtensionsOverride")
    FHazePlaySequenceData TailOverride;

	UPROPERTY(Category = "Locomotion")
    FHazePlaySequenceData Idle;

	UPROPERTY(Category = "Locomotion")
    FHazePlaySequenceData RemoteIdle;

	UPROPERTY(Category = "Locomotion")
    FHazePlaySequenceData RemoteMoving;

	UPROPERTY(Category = "Locomotion")
    FHazePlaySequenceData ResetAttacks;
    
 
};

// Default Charge
class ULocomotionFeatureClockworkBullBossCharge : UHazeLocomotionFeatureBase
{
   default Tag = n"Charge";
    
    UPROPERTY(Category = "Start")
    FHazePlaySequenceData Start180Left;

	UPROPERTY(Category = "Start")
    FHazePlaySequenceData Start180Right;

	UPROPERTY(Category = "Preparing")
    FHazePlayRndSequenceData Charging;

	UPROPERTY(Category = "Preparing")
    FHazePlaySequenceData MovingToTarget1;

	UPROPERTY(Category = "Preparing")
    FHazePlaySequenceData MovingToTarget2;
    
	UPROPERTY(Category = "Attacking")
    FHazePlaySequenceData Rush;

	UPROPERTY(Category = "Impact")
    FHazePlaySequenceData ImpactPlayer;

	UPROPERTY(Category = "Impact")
    FHazePlaySequenceData ImpactWall;

	UPROPERTY(Category = "TailOverride")
    FHazePlaySequenceData TailOverride;

	UPROPERTY(Category = "Impact")
    FHazePlaySequenceData ImpactPillar;
};


// Waiting for network
class ULocomotionFeatureNetworkIdle : UHazeLocomotionFeatureBase
{
   default Tag = n"WatingForNetwork";

    UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Idle;

	UPROPERTY(Category = "Locomotion")
    FHazePlaySequenceData Moving;
 
};