class ULocomotionFeatureCharacterSelect : UHazeLocomotionFeatureBase
{

    default Tag = n"CharacterSelect";

    UPROPERTY(Category = "CharacterSelect")
    FHazePlaySequenceData UnselectedMh;

    UPROPERTY(Category = "CharacterSelect")
    FHazePlaySequenceData SelectedMh;

}