class USapDisableTutorialComponent : UActorComponent
{
    bool bIsTutorialDisabled = false;
}

class ASapDisableTutorialVolume : AVolume
{
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        if (OtherActor != Game::Cody)
            return;

    	auto DisableComp = USapDisableTutorialComponent::GetOrCreate(OtherActor);
    	DisableComp.bIsTutorialDisabled = true;
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        auto DisableComp = USapDisableTutorialComponent::Get(OtherActor);
        if (DisableComp == nullptr)
            return;

        DisableComp.bIsTutorialDisabled = false;
    }
}

UFUNCTION(BlueprintPure, Category = "Weapon|Sap")
bool IsSapTutorialDisabled()
{
    auto DisableComp = USapDisableTutorialComponent::Get(Game::Cody);
    if (DisableComp == nullptr)
        return false;

    return DisableComp.bIsTutorialDisabled;
}