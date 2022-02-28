class ULocomotionFeatureGroundPound : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureGroundPound()
    {
        Tag = n"GroundPound";
    }

    UPROPERTY(Category = "Anims")
    UAnimSequence Start;
    
    UPROPERTY(Category = "Anims")
    UAnimSequence Falling;
    
    UPROPERTY(Category = "Anims")
    UAnimSequence LandStart;
    
    UPROPERTY(Category = "Anims")
    UAnimSequence LandMH;
    
    UPROPERTY(Category = "Anims")
    UAnimSequence LandExit;
        
    UPROPERTY(Category = "Anims")
    UAnimSequence JumpHigh;
    
    UPROPERTY(Category = "Anims")
    UAnimSequence JumpLow;

    UPROPERTY(Category = "Anims")
    UAnimSequence CarryStart;

    UPROPERTY(Category = "Anims")
    UAnimSequence RidingStart;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortGroundPoundStart;

	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortGroundPoundLand;

	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortGroundPoundJump;
};