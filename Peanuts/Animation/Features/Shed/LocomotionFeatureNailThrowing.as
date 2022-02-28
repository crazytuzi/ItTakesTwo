class ULocomotionFeatureNailThrowing: UHazeLocomotionFeatureBase
{
    default Tag = n"NailThrow";


    UPROPERTY()
    FHazePlaySequenceData Throw;

	UPROPERTY()
    FHazePlaySequenceData ThrowLand;

	UPROPERTY()
    FHazePlaySequenceData FallThrow;

};