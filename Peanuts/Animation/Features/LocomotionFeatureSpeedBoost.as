class ULocomotionFeatureSpeedBoost : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSpeedBoost()
    {
        Tag = FeatureName::SpeedBoost;
    }

    //Plays when the giddy up is activated from idle
    UPROPERTY(Category = "Totem Body")
    UAnimSequence ActivatedFromIdle;

    //Plays when the giddy up is activated from a jog
    UPROPERTY(Category = "Totem Body")
    UAnimSequence ActivatedFromJog;
};