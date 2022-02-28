class ULocomotionFeatureMoonBaboonInUfo : UHazeLocomotionFeatureBase 
{

    ULocomotionFeatureMoonBaboonInUfo()
    {
        Tag = n"MoonBaboonInUfo";
    }

    // Mh
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData Mh;

    // Play when a player takes damage
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData DamagePlayer;

    // Mh for when the UFO is knocked down
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData KnockedDownEnter;

    // Mh for when the UFO is knocked down
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData KnockedDown;

    // Programming
    UPROPERTY(Category = "MoonBaboonPhase1")
    FHazePlaySequenceData Programming;

    // Enter for when Cody is lifting up the UFO in the air
    UPROPERTY(Category = "MoonBaboonPhase1")
    FHazePlaySequenceData CodyLifingUFOEnter;

    // Mh for when Cody is lifting up the UFO in the air
    UPROPERTY(Category = "MoonBaboonPhase1")
    FHazePlaySequenceData CodyLifingUFO;

    // Lazer ripped off
    UPROPERTY(Category = "MoonBaboonPhase1")
    FHazePlaySequenceData LazerRippedOff;

    // Animaiton for when the baboon fires a rocket
    UPROPERTY(Category = "MoonBaboonPhase2")
    FHazePlaySequenceData FireRocket;

    // HitReaction for when a rocket hits the UFO
    UPROPERTY(Category = "MoonBaboonPhase2")
    FHazePlaySequenceData RocketHitReaction;

    // HitReaction for when a rocket hits the UFO
    UPROPERTY(Category = "MoonBaboonPhase3")
    FHazePlaySequenceData MoonBaboonGroundPound;
    


}