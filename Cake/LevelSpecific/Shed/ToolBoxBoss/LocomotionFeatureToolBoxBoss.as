class ULocomotionFeatureToolBoxBossFirstPhase : UHazeLocomotionFeatureBase
{
	//Animations for the first phase of the boss fight, where the ToolBoxBoss can slam its wooden plank arm and shoot nails

   default Tag = n"FirstPhase";
    
    UPROPERTY(Category = )
    FHazePlayRndSequenceData Idle;
    
	//Wind-up for the attack
    UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData Start;

	//Ready-state from which the boss can attack
	UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData PlankReadyMH;

	//Attack
    UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData PlankSwing;

	//State where the player can nail the boss' arm to the side
	UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData SwingFinishedMH;

	//The boss' animation if the player doesn't nail it fast enough/if they nail it but recall the nail
	UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData PlankExit;

	//When the arm is nailed to the wood
	UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData ArmStuck;

	UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData ArmNailedMH;

	//When the time is up and the Box frees its arm
	UPROPERTY(Category = "PlankArmAttack")
    FHazePlaySequenceData ArmFreed;

	//When player swings on arm while it's breaking free or is let loose
	UPROPERTY(Category = "NailSwing")
    FHazePlaySequenceData NailSwingEnter;

	UPROPERTY(Category = "NailSwing")
    FHazePlaySequenceData NailSwingMH;

	UPROPERTY(Category = "NailSwing")
    FHazePlaySequenceData NailSwingExit;

	//Hit Reactions for when the player strikes the Padlocks
	UPROPERTY(Category = "Padlocks")
    FHazePlaySequenceData FrontPadLockMh;

	UPROPERTY(Category = "Padlocks")
    FHazePlaySequenceData BackPadLockMh;
	
	UPROPERTY(Category = "Padlocks")
    FHazePlaySequenceData FrontPadLockHit;

	UPROPERTY(Category = "Padlocks")
    FHazePlaySequenceData BackPadLockHit;

	//Firing Nails from the top of compartment on top. Override only playing on FrontMiddleHinge and down
	UPROPERTY(Category = "NailRainOverride")
    FHazePlaySequenceData NailRainStart;

	UPROPERTY(Category = "NailRainOverride")
    FHazePlaySequenceData NailRainFiring;

	UPROPERTY(Category = "NailRainOverride")
    FHazePlaySequenceData NailRainExit;

	//When the first padlock has been destroyed and that cutscene has played out, the ToolBox can take out a drill and use it to spin the platform

	UPROPERTY(Category = "DrillAttack")
    FHazePlaySequenceData DrillIsReadyMh;

	UPROPERTY(Category = "DrillAttack")
    FHazePlaySequenceData DrillAttackStartFromCutscene;

	//The start of the attack that plays on subsequent cycles after the first cutscene attack intro

	UPROPERTY(Category = "DrillAttack")
    FHazePlaySequenceData DrillAttackStart;

	UPROPERTY(Category = "DrillAttack")
    FHazePlaySequenceData DrillAttackMh;

	UPROPERTY(Category = "DrillAttack")
    FHazePlaySequenceData DrillAttackExit;

	//Face that plays over the rest of the moves

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData ToMh;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData ToReady;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData ReadyIdle;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData ToUpset;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData UpsetIdle;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData ToLaughing;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData LaughingIdle;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData LaughFinished;
	
	UPROPERTY(Category = "Face")
    FHazePlayRndSequenceData HitReaction;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData AttackFace;

	
};

class ULocomotionFeatureToolBoxBossSecondPhase : UHazeLocomotionFeatureBase
{
	//Animations for the second phase of the boss fight, where the ToolBoxBoss can slam its spade arm and shoot nails

   default Tag = n"SecondPhase";

	UPROPERTY(Category = )
    FHazePlayRndSequenceData Idle;
    
	//Wind-up for the attack
    UPROPERTY(Category = "SpadeArmAttack")
    FHazePlaySequenceData AttackStart;

	//Ready-state from which the boss can attack
	UPROPERTY(Category = "SpadeArmAttack")
    FHazePlayBlendSpaceData AttackReadyMH;

	//Attack
    UPROPERTY(Category = "SpadeArmAttack")
    FHazePlayBlendSpaceData ArmSlam;

	//Wind-up for the finishing slam
    UPROPERTY(Category = "SpadeArmFinisher")
    FHazePlaySequenceData FinisherStart;

	//Wind-up for the finishing slam from regular MH
    UPROPERTY(Category = "SpadeArmFinisher")
    FHazePlaySequenceData FinisherStartFromIdle;

	//Ready-state from which the boss can execute the finishing slam
	UPROPERTY(Category = "SpadeArmFinisher")
    FHazePlaySequenceData FinisherReadyMH;

	//Attack
    UPROPERTY(Category = "SpadeArmFinisher")
    FHazePlaySequenceData FinisherSlam;

	//State where the player can jump on the spade and launch Cody into the air
	UPROPERTY(Category = "SpadeArmFinisher")
    FHazePlaySequenceData SlamFinishedMH;

	UPROPERTY(Category = "SpadeArmFinisher")
	FHazePlaySequenceData Launcher;

	UPROPERTY(Category = "SpadeArmFinisher")
	FHazePlaySequenceData LeftPadLockHit;

	UPROPERTY(Category = "SpadeArmFinisher")
	FHazePlaySequenceData RightPadLockHit;

	//The boss returning to regular mh
	UPROPERTY(Category = "SpadeArmFinisher")
    FHazePlaySequenceData FinisherExit;

	//Wind-up for the spin-attack
	UPROPERTY(Category = "SpinAttack")
	FHazePlaySequenceData SpinPrepare;

	//Wind-up mh for the spin-attack
	UPROPERTY(Category = "SpinAttack")
	FHazePlaySequenceData ReadyMh;

	//Spin-attack
	UPROPERTY(Category = "SpinAttack")
	FHazePlayRndSequenceData SpinAttack;

	//Face that plays over the rest of the moves
	UPROPERTY(Category = "Face")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData SpitStart;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData SpitReady;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData SpitSaw;
	
	UPROPERTY(Category = "Face")
	FHazePlaySequenceData ToMh;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData ToReady;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData ReadyIdle;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData FinisherAttack;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData FinishedMh;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData FinisherRecovery;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData ToLaughing;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData LaughingIdle;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData LaughFinished;
	
	UPROPERTY(Category = "Face")
    FHazePlayRndSequenceData HitReaction;

	UPROPERTY(Category = "Face")
	FHazePlaySequenceData AttackFace;


	//Firing Nails from the top of compartment on top. Override only playing on FrontMiddleHinge and down
	UPROPERTY(Category = "NailRainOverride")
    FHazePlaySequenceData NailRainStart;

	UPROPERTY(Category = "NailRainOverride")
    FHazePlaySequenceData NailRainFiring;

	UPROPERTY(Category = "NailRainOverride")
    FHazePlaySequenceData NailRainExit;

};