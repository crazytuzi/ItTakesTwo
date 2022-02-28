UCLASS(NotBlueprintable, meta = ("Pickup (time marker)"))
class UAnimNotify_Pickup : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Pickup (time marker)";
	}
};