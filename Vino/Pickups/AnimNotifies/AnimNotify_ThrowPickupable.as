UCLASS(NotBlueprintable, meta = ("Throw Pickupable (time marker)"))
class UAnimNotify_ThrowPickupable : UAnimNotify
{
    UFUNCTION(BlueprintOverride)
    FString GetNotifyName() const
    {
        return "Throw Pickupable (time marker)";
    }
}