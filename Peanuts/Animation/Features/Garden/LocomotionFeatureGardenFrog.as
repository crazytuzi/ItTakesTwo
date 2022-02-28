class ULocomotionFeatureGardenFrog : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureGardenFrog()
    {
        Tag = n"GardenFrog";
    }

    UPROPERTY(Category = "Enter")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Exit")
    FHazePlaySequenceData Exit;

	UPROPERTY(Category = "Tongue")
    FHazePlaySequenceData Tongue;

	UPROPERTY(Category = "Death")
    FHazePlaySequenceData Death;

	UPROPERTY(Category = "WaterJump")
    FHazePlaySequenceData WaterJump;

    // Movement BlendSpace
    UPROPERTY(Category = "Idle/Turn/Charge")
    FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Crawl")
    FHazePlayBlendSpaceData CrawlBS;

	UPROPERTY(Category = "Idle/Turn/Charge")
    FHazePlayRndSequenceData CroakAdditive;

    UPROPERTY(Category = "Jump")
    FHazePlaySequenceData JumpStart;

	UPROPERTY(Category = "Jump")
    FHazePlayBlendSpaceData InAirBS;

	UPROPERTY(Category = "Jump")
    FHazePlaySequenceData Land;

	UPROPERTY(Category = "Hop")
    FHazePlaySequenceData HopStart;

	UPROPERTY(Category = "Hop")
    FHazePlayBlendSpaceData HopInAirBS;

	UPROPERTY(Category = "Hop")
    FHazePlaySequenceData HopLand;

	UPROPERTY(Category = "Hop")
    FHazePlaySequenceData ShortHop;

	UPROPERTY(Category = "Hop")
    FHazePlaySequenceData ShortHopSettle;

	UPROPERTY(Category = "Hop")
    FHazePlaySequenceData WalkOffEdge;


};