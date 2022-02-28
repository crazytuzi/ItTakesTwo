class ULocomotionFeatureFireFlies : UHazeLocomotionFeatureBase 
{

    ULocomotionFeatureFireFlies()
    {
        Tag = n"FireFlies";
    }

    // Blendspace moving sideways
    UPROPERTY(Category = "FireFlies")
    FHazePlayBlendSpaceData Floating;

    // Charge anim
    UPROPERTY(Category = "FireFlies")
    FHazePlaySequenceData Charge;

    // Launch animation
    UPROPERTY(Category = "FireFlies")
    FHazePlayBlendSpaceData Launch;

    // Launch animation
    UPROPERTY(Category = "FireFlies")
    FHazePlaySequenceData FreeFalling;

    // ! NOTE: MUST BE MESH SPACE ADDITIVE ! - Additive 360 degree rotation forward (This will be played backwards for rotating backwards)
    UPROPERTY(Category = "FireFliesRotation")
    bool RotateFwdInLaunch = false;

    // ! NOTE: MUST BE MESH SPACE ADDITIVE ! - Additive 360 degree rotation forward (This will be played backwards for rotating backwards)
    UPROPERTY(Category = "FireFliesRotation")
    FHazePlaySequenceData AdditiveRotationFwd;

    // ! NOTE: MUST BE LOCAL SPACE ADDITIVE ! - Additive 360 degree rotation right (this will be played backwards for rotating left)
    UPROPERTY(Category = "FireFliesRotation")
    FHazePlaySequenceData AdditiveRotationRight;

    
}