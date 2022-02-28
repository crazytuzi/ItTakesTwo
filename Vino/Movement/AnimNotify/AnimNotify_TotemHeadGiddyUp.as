UCLASS(NotBlueprintable, meta = ("Totem Head GiddyUp (time marker)"))
class UAnimNotify_TotemHeadGiddyUp : UAnimNotify
{
    UFUNCTION(BlueprintOverride)
    FString GetNotifyName() const
    {
        return "Totem Head GiddyUp (time marker)";
    }
}