UCLASS(NotBlueprintable, meta = ("Pickup Rotation Start (time marker)"))
class UAnimNotify_PickupRotationStart : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Pickup Rotation Start(time marker)";
	}
};