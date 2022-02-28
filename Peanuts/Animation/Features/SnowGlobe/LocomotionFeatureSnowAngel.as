class ULocomotionFeatureSnowAngel : UHazeLocomotionFeatureBase
{
    default Tag = n"SnowAngel";

    UPROPERTY(Category = "SnowAngel")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "SnowAngel")
    FHazePlayBlendSpaceData SnowAngelBlendspace;

	UPROPERTY(Category = "SnowAngel")
    FHazePlaySequenceData Exit;

};