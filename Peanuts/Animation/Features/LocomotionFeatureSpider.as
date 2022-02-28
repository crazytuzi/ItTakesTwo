class ULocomotionFeatureSpider : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSpider()
    {
        Tag = n"Spider";
    }

    UPROPERTY(Category = "Dodges")
    UAnimSequence DodgeRight;

    UPROPERTY(Category = "Dodges")
    UAnimSequence DodgeLeft;

    UPROPERTY(Category = "Attacks")
    UAnimSequence PouncePrepare;

    UPROPERTY(Category = "Attacks")
    UAnimSequence PouncePrepareMH;

    UPROPERTY(Category = "Attacks")
    UAnimSequence Pounce;

    UPROPERTY(Category = "Attacks")
    UAnimSequence AttackMH;

    UPROPERTY(Category = "Attacks")
    UAnimSequence Kill;

    UPROPERTY(Category = "Reactions")
    UAnimSequence Pierced;

    UPROPERTY(Category = "Reactions")
    UAnimSequence PiercedMH;

    UPROPERTY(Category = "Reactions")
    UAnimSequence PiercedJumpFree;

    UPROPERTY(Category = "Reactions")
    UAnimSequence PiercedDuringAttack;

    UPROPERTY(Category = "Reactions")
    UAnimSequence Hammered;

};