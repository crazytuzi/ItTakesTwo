class ULocomotionFeatureTreeBeetle : UHazeLocomotionFeatureBase
{
    default Tag = n"Beetle";

  	UPROPERTY(Category = "SlotAnims")
    UAnimSequence Entrance;

    UPROPERTY(Category = "SlotAnims")
    UAnimSequence EntranceEnd;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Idle_Mh;

    //UPROPERTY(Category = "Beetle")
	//UBlendSpace Turn;

    UPROPERTY(Category = "Beetle")
	FHazePlayBlendSpaceData TurnFast;

    UPROPERTY(Category = "Beetle")
    FHazePlaySequenceData TelegraphCharge;

    UPROPERTY(Category = "Beetle")
    FHazePlaySequenceData ChargeStart;

    UPROPERTY(Category = "Beetle")
	FHazePlayBlendSpaceData Charge;

    UPROPERTY(Category = "Beetle")
    FHazePlaySequenceData Gore;

    UPROPERTY(Category = "Beetle")
    FHazePlaySequenceData Stomp;

    UPROPERTY(Category = "PounceAttack")
    FHazePlaySequenceData TelegraphPounce;

    UPROPERTY(Category = "PounceAttack")
    FHazePlaySequenceData Pounce_Start;

    UPROPERTY(Category = "PounceAttack")
    FHazePlaySequenceData Pounce_Mh;

    UPROPERTY(Category = "PounceAttack")
    FHazePlaySequenceData Pounce_Land;

    UPROPERTY(Category = "MultiSlamAttack")
    FHazePlaySequenceData TelegraphMultiSlam;

    UPROPERTY(Category = "MultiSlamAttack")
    FHazePlaySequenceData MultiSlam;

    UPROPERTY(Category = "Beetle")
    FHazePlaySequenceData Recover;

    UPROPERTY(Category = "Damage")
    FHazePlaySequenceData SapExplosion;

    UPROPERTY(Category = "Damage")
    FHazePlaySequenceData Stunned_MH;

    UPROPERTY(Category = "Damage")
    FHazePlaySequenceData Stunned_End;

    UPROPERTY(Category = "AdditiveDamage")
	FHazePlaySequenceData AdditiveHurt_Front;

    UPROPERTY(Category = "AdditiveDamage")
	FHazePlaySequenceData AdditiveHurt_Left;

    UPROPERTY(Category = "AdditiveDamage")
	FHazePlaySequenceData AdditiveHurt_Right;


};