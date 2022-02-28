class ULocomotionFeatureGiddyUp : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureGiddyUp()
    {
        Tag = FeatureName::GiddyUp;
    }

    //Plays when the giddy up is activated from idle
    UPROPERTY(Category = "Totem Body")
    UAnimSequence ActivatedFromIdle;

    //Plays when the giddy up is activated from a jog
    UPROPERTY(Category = "Totem Body")
    UAnimSequence ActivatedFromJog;
};