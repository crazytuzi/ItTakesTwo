UCLASS(NotBlueprintable, HideCategories = "Collision Rendering Input Actor LOD Cooking")
class ABlockLedgeGrabVolume : AVolume
{
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if(Player != nullptr)
        {
           Player.BlockCapabilities(n"LedgeGrab", this);
        }
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if(Player != nullptr)
        {
           Player.UnblockCapabilities(n"LedgeGrab", this);
        }
    }
}