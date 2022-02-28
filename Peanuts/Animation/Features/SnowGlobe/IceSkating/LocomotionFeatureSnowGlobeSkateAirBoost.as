class ULocomotionFeatureSnowGlobeSkateAirBoost : UHazeLocomotionFeatureBase
{
    default Tag = n"SkateAirBoost";

    UPROPERTY(Category = "AirBoost")
    FHazePlayRndSequenceData Boost;

	UPROPERTY(Category = "AirBoost")
    FHazePlayRndSequenceData BoostVariant;

	UPROPERTY(Category = "AirGlideBoost")
    FHazePlayRndSequenceData GlideBoost;

	UPROPERTY(Category = "AirGlideBoost")
    FHazePlayRndSequenceData GlideBoostVariant;

};