

class ULocomotionFeatureDigitalWatch : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureDigitalWatch()
    {
        Tag = n"DigitalWatch";
    }

	// General movement

    // 
    UPROPERTY(Category = "DigitalWatch")
    FHazePlaySequenceData DigitalWatch;

    UPROPERTY(Category = "DigitalWatch")
    FHazePlaySequenceData DigitalWatch1;

	UPROPERTY(Category = "DigitalWatch")
    FHazePlaySequenceData DigitalWatch2;

	UPROPERTY(Category = "DigitalWatch")
    FHazePlaySequenceData DigitalWatch3;

	UPROPERTY(Category = "TeleportExit")
    FHazePlaySequenceData TeleportExit;

	UPROPERTY(Category = "TeleportExit")
    FHazePlaySequenceData TeleportExit1;

	UPROPERTY(Category = "TeleportExit")
    FHazePlaySequenceData TeleportExit2;

	UPROPERTY(Category = "TeleportExit")
    FHazePlaySequenceData TeleportExit3;

	UPROPERTY(Category = "TeleportEnter")
    FHazePlaySequenceData TeleportEnter;






	

};