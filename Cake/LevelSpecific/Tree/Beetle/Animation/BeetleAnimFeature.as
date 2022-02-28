class UBeetleAnimFeature : UHazeLocomotionFeatureBase
{
    UBeetleAnimFeature()
    {
        Tag = n"BeetleWalk";
    }

    UPROPERTY(Category = "Beetle")
    UAnimSequence Entrance;

    UPROPERTY(Category = "Beetle")
    UAnimSequence EntranceEnd;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Idle_Mh;

    UPROPERTY(Category = "Beetle")
	UBlendSpace Turn;

    UPROPERTY(Category = "Beetle")
	UBlendSpace TurnFast;

    UPROPERTY(Category = "Beetle")
    UAnimSequence TelegraphCharge;

    UPROPERTY(Category = "Beetle")
    UAnimSequence ChargeStart;

    UPROPERTY(Category = "Beetle")
	UBlendSpace Charge;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Gore;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Stomp;

    UPROPERTY(Category = "Beetle")
    UAnimSequence TelegraphPounce;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Pounce_Start;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Pounce_Mh;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Pounce_Land;

    UPROPERTY(Category = "Beetle")
    UAnimSequence TelegraphMultiSlam;

    UPROPERTY(Category = "Beetle")
    UAnimSequence MultiSlam;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Recover;

    UPROPERTY(Category = "Beetle")
    UAnimSequence SapExplosion;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Stunned_Start;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Stunned_MH;

    UPROPERTY(Category = "Beetle")
    UAnimSequence Stunned_End;

    UPROPERTY(Category = "Beetle")
	UAnimSequence AdditiveHurt_Front;

    UPROPERTY(Category = "Beetle")
	UAnimSequence AdditiveHurt_Left;

    UPROPERTY(Category = "Beetle")
	UAnimSequence AdditiveHurt_Right;
}
