UCLASS(NotBlueprintable, HideCategories = "Collision Rendering Input Actor LOD Cooking")
class AFreeFallSafetyVolume : AVolume
{
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if(Player != nullptr && Player.HasControl())
        {
           Player.SetCapabilityActionState(n"FreeFallSafety", EHazeActionState::Active);
        }
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if(Player != nullptr && Player.HasControl())
        {
           Player.SetCapabilityActionState(n"FreeFallSafety", EHazeActionState::Inactive);
        }
    }
}