class UCastleEnemyChargerTrapFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyChargerTrapFeature()
    {
        Tag = n"CastleEnemyChargerTrapped";
    }

	UPROPERTY()
    FHazePlaySequenceData Enter;

	UPROPERTY()
    FHazePlaySequenceData MH;


	UPROPERTY(Category = "Right Hand")
    FHazePlaySequenceData RightHandHurt;

	UPROPERTY(Category = "Right Hand")
    FHazePlaySequenceData RightHandHurtMH;

	UPROPERTY(Category = "Right Hand")
    FHazePlaySequenceData RightHandHitReaction;

	UPROPERTY(Category = "Right Hand")
    FHazePlaySequenceData RightHandRecover;

	UPROPERTY(Category = "Right Hand")
    FHazePlaySequenceData RightHandDeath;


	
	UPROPERTY(Category = "Left Hand")
    FHazePlaySequenceData LeftHandHurt;

	UPROPERTY(Category = "Left Hand")
    FHazePlaySequenceData LeftHandHurtMH;

	UPROPERTY(Category = "Left Hand")
    FHazePlaySequenceData LeftHandHitReaction;

	UPROPERTY(Category = "Left Hand")
    FHazePlaySequenceData LeftHandRecover;

	UPROPERTY(Category = "Left Hand")
    FHazePlaySequenceData LeftHandDeath;
};