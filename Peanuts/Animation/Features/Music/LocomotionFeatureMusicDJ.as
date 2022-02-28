enum EHazeMusicDJStation {
	Vinyl,
	Smoke,
	Fader,
	Pads
};


class ULocomotionFeatureMusicDJ : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureMusicDJ()
    {
        Tag = n"MusicDJ";
    }

    UPROPERTY(Category = "Vinyl")
    FHazePlaySequenceData Vinyl;

	UPROPERTY(Category = "Smoke")
    FHazePlaySequenceData Smoke;

	UPROPERTY(Category = "Fader")
    FHazePlaySequenceData Fader;

	UPROPERTY(Category = "Pads")
    FHazePlayRndSequenceData Pads;

};