enum EHazeSelectStartAnim {
	Default,
	FromDash,
	NotJumpable,
};

class ULocomotionFeatureWallSlide : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureWallSlide()
    {
        Tag = FeatureName::WallMovement;
    }
    
    UPROPERTY(Category = "Locomotion Wallslide")
    FHazePlaySequenceData WallSlide;

	// Wallsliding mh, w/ stick input to indicate character is ready to Dash outwards
	UPROPERTY(Category = "Locomotion Wallslide")
    FHazePlaySequenceData WallSlideReadyToDash;

    UPROPERTY(Category = "Locomotion Wallslide")
    FHazePlaySequenceData WallJump;

	UPROPERTY(Category = "Locomotion Wallslide")
    FHazePlaySequenceData WallJumpHorizontal;

	// Default enter animation
    UPROPERTY(Category = "Locomotion Wallslide")
    FHazePlaySequenceData IntoWallSlide;

	// Enter animation if player does a Dash -> WallSlide
	UPROPERTY(Category = "Locomotion Wallslide")
    FHazePlaySequenceData IntoWallSlideFromDash;

	// Enter animation If player does a WallJump -> Dash -> WallSlide
	UPROPERTY(Category = "Locomotion Wallslide")
    FHazePlaySequenceData IntoWallSlideNotJumpableStart;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;

};