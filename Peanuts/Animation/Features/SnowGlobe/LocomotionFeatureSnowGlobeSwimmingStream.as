class ULocomotionFeatureSnowGlobeSwimmingStream : UHazeLocomotionFeatureBase
{
    default Tag = n"SwimmingStream";

	// The max rotation rate it'll try to achive
	UPROPERTY(Category = "Spinning Values")
	float MaxTargetRotationRate = 35.f;

	// When it reaches this rotation rate it'll start to accelerate down towards zero instead.
	UPROPERTY(Category = "Spinning Values")
	float StartSlowingDownAt = 25.f;

	// Acceleration to increase the rotation rate towards MaxTargetRotationRate
	UPROPERTY(Category = "Spinning Values")
	float AccelerationIncrease = 0.6f;

	// Acceleration to decrease the rotation rate towards 0
	UPROPERTY(Category = "Spinning Values")
	float AccelerationDecrease = 0.4f;

    // Mh
    UPROPERTY(Category = "SwimmingStream")
    FHazePlayBlendSpaceData SwimmingStream;

    UPROPERTY(Category = "SwimmingStream")
    FHazePlaySequenceData SpinningMh;

	UPROPERTY(Category = "SwimmingStream")
    FHazePlaySequenceData AdjustSpinning;
	
};