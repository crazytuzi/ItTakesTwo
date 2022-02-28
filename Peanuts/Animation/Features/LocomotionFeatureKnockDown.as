class ULocomotionFeatureKnockDown : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureKnockDown()
    {
        Tag = FeatureName::KnockDown;
    }

    // Force from character's front
    UPROPERTY(Category = "KnockDown Front")
    FHazePlaySequenceData KnockDown_Front_Start;

    // Force from character's front
    UPROPERTY(Category = "KnockDown Front")
    FHazePlaySequenceData KnockDown_Front_mh;

    // Force from character's front
    UPROPERTY(Category = "KnockDown Front")
    FHazePlaySequenceData KnockDown_Front_Land;

    // Force from character's back
    UPROPERTY(Category = "KnockDown Back")
    FHazePlaySequenceData KnockDown_Back_Start;

    // Force from character's back
    UPROPERTY(Category = "KnockDown Back")
    FHazePlaySequenceData KnockDown_Back_mh;

    // Force from character's back
    UPROPERTY(Category = "KnockDown Back")
    FHazePlaySequenceData KnockDown_Back_Land;

    // Force from character's left
    UPROPERTY(Category = "KnockDown Left")
    FHazePlaySequenceData KnockDown_Left_Start;

    // Force from character's left
    UPROPERTY(Category = "KnockDown Left")
    FHazePlaySequenceData KnockDown_Left_mh;

    // Force from character's left
    UPROPERTY(Category = "KnockDown Left")
    FHazePlaySequenceData KnockDown_Left_Land;

    // Force from character's right
    UPROPERTY(Category = "KnockDown Right")
    FHazePlaySequenceData KnockDown_Right_Start;

    // Force from character's right
    UPROPERTY(Category = "KnockDown Right")
    FHazePlaySequenceData KnockDown_Right_mh;

    // Force from character's right
    UPROPERTY(Category = "KnockDown Right")
    FHazePlaySequenceData KnockDown_Right_Land;
};