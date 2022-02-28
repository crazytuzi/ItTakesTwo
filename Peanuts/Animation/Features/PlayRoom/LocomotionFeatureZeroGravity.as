class ULocomotionFeatureZeroGravity : UHazeLocomotionFeatureBase 
{

    ULocomotionFeatureZeroGravity()
    {
        Tag = n"ZeroGravity";
    }
	

    // Blendspace moving sideways
    UPROPERTY(Category = "ZeroGravityMovement")
    FHazePlayBlendSpaceData Movement;

    // ! NOTE: MUST BE MESH SPACE ADDITIVE ! - Additive 360 degree rotation forward (This will be played backwards for rotating backwards)
    UPROPERTY(Category = "ZeroGravityRotation")
    FHazePlaySequenceData AdditiveRotationFwd;

    // ! NOTE: MUST BE LOCAL SPACE ADDITIVE ! - Additive 360 degree rotation right (this will be played backwards for rotating left)
    UPROPERTY(Category = "ZeroGravityRotation")
    FHazePlaySequenceData AdditiveRotationRight;

	UPROPERTY(Category = "BlendTime")
	float BlendTime = 0.5f;


}