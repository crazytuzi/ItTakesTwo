class ULocomotionFeatureDrillSaw : UHazeLocomotionFeatureBase

{
    
default Tag = n"DrillSaw";

UPROPERTY(Category = "DrillSaw")
FHazePlaySequenceData ReadyMH;

UPROPERTY(Category = "DrillSaw")
FHazePlaySequenceData StartFromCS;

UPROPERTY(Category = "DrillSaw")
FHazePlaySequenceData Start;

UPROPERTY(Category = "DrillSaw")
FHazePlaySequenceData Mh;

UPROPERTY(Category = "DrillSaw")
FHazePlaySequenceData Exit;

};