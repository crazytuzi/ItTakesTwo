import Cake.LevelSpecific.Shed.ZombieNails.ZombieNailActor;

class UAttachedNailCounterComponent : UActorComponent
{
    // UPROPERTY()
    // int AttachedNailsCount = 0;

    UPROPERTY()
    int MaxAttachedNailsCount = 5;

    bool DecrementOnCooldown = false;

    float Cooldown = 1.0f;
    float CooldownCounter = 0.f;

    TArray<AZombieNailActor> AttachedNails;

    UFUNCTION(BlueprintCallable)
    void IncrementNails(AZombieNailActor NailRef)
    {
        //AttachedNailsCount = FMath::Clamp(AttachedNailsCount + 1.f, 0.f, MaxAttachedNailsCount);
        AttachedNails.Add(NailRef);
        if (AttachedNails.Num() >= MaxAttachedNailsCount)
            KillPlayer();
    }

    UFUNCTION(BlueprintCallable)
    void DecrementNails()
    {
        // AttachedNailsCount = FMath::Clamp(AttachedNailsCount - 1.f, 0.f, MaxAttachedNailsCount);
        if(AttachedNails.Num() > 0 && !DecrementOnCooldown)
        {
            AZombieNailActor NailToRemove = AttachedNails[0];
            NailToRemove.DetachNail();
            AttachedNails.Remove(NailToRemove);
            DecrementOnCooldown = true;
        }
    }

    UFUNCTION(BlueprintCallable)
    void KillPlayer()
    {

    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        HandleDecrementCooldown(DeltaSeconds);
    }

    void HandleDecrementCooldown(float DeltaSeconds)
    {
        if(DecrementOnCooldown)
        {
            CooldownCounter += DeltaSeconds;
            if(CooldownCounter >= Cooldown)
            {
                DecrementOnCooldown = false;
                CooldownCounter = 0.f;
            }
        }
    }
}