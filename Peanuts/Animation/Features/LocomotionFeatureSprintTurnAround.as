class ULocomotionFeatureSprintTurnAround : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSprintTurnAround()
    {
        Tag = n"SprintTurnAround";
    }

    UPROPERTY(Category = "SprintTurnAround")
    FHazePlaySequenceData SprintTurn;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;

};