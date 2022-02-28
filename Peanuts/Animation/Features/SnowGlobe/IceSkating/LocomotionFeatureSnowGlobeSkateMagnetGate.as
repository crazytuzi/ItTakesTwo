class ULocomotionFeatureSnowGlobeSkateMagnetGate : UHazeLocomotionFeatureBase
{
   default Tag = n"MagnetGate";
      
    UPROPERTY(Category = "Gate")
    FHazePlaySequenceData BeginPull;
    
	UPROPERTY(Category = "Gate")
    FHazePlaySequenceData AirBeginPull;

	UPROPERTY(Category = "Gate")
    FHazePlaySequenceData AirGlideBeginPull;

    UPROPERTY(Category = "Gate")
    FHazePlayBlendSpaceData PullingMh;

    UPROPERTY(Category = "Gate")
    FHazePlaySequenceData StopPull;

    // Launching onto ground
	UPROPERTY(Category = "Gate")
    FHazePlaySequenceData LaunchGrounded;

    // Launch into the air (but not air glide)
    UPROPERTY(Category = "Gate")
    FHazePlaySequenceData LaunchAir;

    // Launching over a big gap going into air-glide!
    UPROPERTY(Category = "Gate")
    FHazePlaySequenceData LaunchAirGlide;
};