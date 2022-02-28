class ULocomotionFeatureLeafBoat : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureLeafBoat()
    {
        Tag = n"LeafBoat";
    }

    // The animation when you enter steering state
    UPROPERTY(Category = "Locomotion LeafBoat")
    UAnimSequence LeafBoatEnter;

    // MH and movement
    UPROPERTY(Category = "Locomotion LeafBoat")
    UBlendSpaceBase LeafBoatBS;

    // The animation when you exit steering state
    UPROPERTY(Category = "Locomotion LeafBoat")
    UAnimSequence LeafBoatExit;

};