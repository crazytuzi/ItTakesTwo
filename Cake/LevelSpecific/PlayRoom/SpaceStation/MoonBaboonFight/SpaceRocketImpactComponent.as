event void FOnHitByRocket();

class USpaceRocketImpactComponent : UActorComponent
{
    UPROPERTY()
    FOnHitByRocket OnHitByRocket;

    UPROPERTY()
    bool bDestroyRocket = true;

    void HitByRocket()
    {
        OnHitByRocket.Broadcast();
    }
}