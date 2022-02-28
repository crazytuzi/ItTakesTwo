class ULocomotionFeatureGardenSnailRace : UHazeLocomotionFeatureBase
{

    default Tag = n"SnailRace";

	UPROPERTY(BlueprintReadOnly, Category = "SnailRace")
    FHazePlaySequenceData Enter;

    UPROPERTY(BlueprintReadOnly, Category = "SnailRace")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "SnailRace")
    FHazePlaySequenceData Dash;

	UPROPERTY(BlueprintReadOnly, Category = "SnailRace")
    FHazePlaySequenceData Stunned;

}