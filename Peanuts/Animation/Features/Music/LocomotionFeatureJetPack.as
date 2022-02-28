class ULocomotionFeatureJetPack: UHazeLocomotionFeatureBase
{
   default Tag = n"JetPack";

    UPROPERTY()
    FHazePlaySequenceData InitialStart;

	UPROPERTY()
    FHazePlaySequenceData DirectStop;

	UPROPERTY()
    FHazePlayBlendSpaceData HoverBS;

    UPROPERTY()
    FHazePlayBlendSpaceData StartBoost;

	UPROPERTY()
    FHazePlayBlendSpaceData FlyBS;

    UPROPERTY()
    FHazePlayBlendSpaceData StopBoost;

	UPROPERTY()
    FHazePlaySequenceData End;

	UPROPERTY()
    FHazePlaySequenceData BarrelRollLeft;

	UPROPERTY()
    FHazePlaySequenceData BarrelRollRight;

	UPROPERTY(Category = "Cymbal")
    FHazePlayBlendSpaceData AimCymbal;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData ThrowCymbal;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData ThrowCymbalDown;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData ThrowCymbalUp;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData CatchCymbal;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData RightArmOverride;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData HoverArmOverride;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData Equip;

	UPROPERTY(Category = "Cymbal")
    FHazePlaySequenceData Unequip;
};