class ULocomotionFeatureControllingUFO : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureControllingUFO()
    {
        Tag = n"ControllableUFO";
    }

	UPROPERTY(Category = "Controlling Ufo")
	FHazePlayBlendSpaceData ControllingUFO;

}