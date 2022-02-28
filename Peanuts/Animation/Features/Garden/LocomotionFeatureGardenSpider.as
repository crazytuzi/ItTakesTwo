class ULocomotionFeatureGardenSpider : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureGardenSpider()
    {
        Tag = n"GardenSpider";
    }

    UPROPERTY(Category = "Enter")
    FHazePlaySequenceData Enter;

    // Movement BlendSpace
    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBS;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData TurnInPlaceBS;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData StopBS;

	UPROPERTY(Category = "Prepare")
    FHazePlayBlendSpaceData PrepareBS;

	UPROPERTY(Category = "Prepare")
    FHazePlaySequenceData PrepareEnter;

	UPROPERTY(Category = "Prepare")
    FHazePlaySequenceData PrepareExit;

	UPROPERTY(Category = "WebRepel")
    FHazePlaySequenceData Transition90;

	UPROPERTY(Category = "WebRepel")
    FHazePlaySequenceData WebRepelUpsideDown;

    UPROPERTY(Category = "WebRepel")
    FHazePlaySequenceData WebRepelUpsideDownMH;

    UPROPERTY(Category = "WebRepel")
    FHazePlaySequenceData WebRepelUpsideDownLand;

    UPROPERTY(Category = "PlayerAiming")
    FHazePlayBlendSpaceData AimMh;
	
	UPROPERTY(Category = "PlayerAiming")
    FHazePlaySequenceData Shoot;
		
	UPROPERTY(Category = "PlayerAiming")
    FHazePlaySequenceData AttachedStart;

	UPROPERTY(Category = "PlayerAiming")
    FHazePlaySequenceData Attached;
		
	UPROPERTY(Category = "PlayerAiming")
    FHazePlaySequenceData Catch;
			
	UPROPERTY(Category = "PlayerAiming")
    FHazePlaySequenceData AttachCatch;

	UPROPERTY(Category = "Falling")
    FHazePlaySequenceData Fall;

	UPROPERTY(Category = "PlayerAiming")
    FHazePlaySequenceData ThrowLand;

	UPROPERTY(Category = "PlayerAiming")
    FHazePlaySequenceData AttachRetract;
			
};