class ULocomotionFeatureSlowStrafe : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSlowStrafe()
    {
        Tag = n"SlowStrafe";
    }

	UPROPERTY(Category = "SlowStrafe")
    FHazePlayBlendSpaceData SlowStrafe;

	UPROPERTY(Category = "SlowStrafe")
    FHazePlayBlendSpaceData TurnInPlace;

	UPROPERTY(Category = "LookAT")
    bool bUseLookAt;


};