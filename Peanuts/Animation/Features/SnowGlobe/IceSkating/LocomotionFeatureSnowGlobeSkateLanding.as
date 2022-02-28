class ULocomotionFeatureSnowGlobeSkateLanding : UHazeLocomotionFeatureBase
{
     default Tag = n"SkateLanding";

    //The animation playing when landing with low velocity and not giving stick input
	UPROPERTY(Category = "RegularLanding")
	FHazePlaySequenceData Landing;

    //The animation playing when landing with velocity and not giving stick input
	UPROPERTY(Category = "RegularLanding")
	FHazePlaySequenceData GlideLanding;

	//The animation playing when landing with velocity and giving stick input
	UPROPERTY(Category = "RegularLanding")
	FHazePlaySequenceData LandingInMotion;

	//The animation playing when landing with low velocity and not giving stick input
	UPROPERTY(Category = "LandFromAirGlide")
	FHazePlaySequenceData AirGlideLanding;

	//The animation playing when landing with velocity and not giving stick input
	UPROPERTY(Category = "LandFromAirGlide")
	FHazePlaySequenceData AirGlideGlideLanding;

	//The animation playing when landing with velocity and giving stick input
	UPROPERTY(Category = "LandFromAirGlide")
	FHazePlaySequenceData AirGlideLandingInMotion;
};