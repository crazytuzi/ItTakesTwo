class ULocomotionFeatureWaspLarva : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureWaspLarva()
    {
        Tag = n"WaspLarva";
    }

    UPROPERTY(Category = "Movement")
    UAnimSequence Idle_Mh;

    UPROPERTY(Category = "Movement")
    UAnimSequence Crawl_Mh;

    UPROPERTY(Category = "Eating")
    UAnimSequence Eat;

    UPROPERTY(Category = "Attack")
    UAnimSequence Explode;

    UPROPERTY(Category = "Hatching")
    UAnimSequence Hatch_Start;

    UPROPERTY(Category = "Hatching")
    UAnimSequence Hatch_Mh;

    UPROPERTY(Category = "Hatching")
    UAnimSequence Hatch_Land;
}
