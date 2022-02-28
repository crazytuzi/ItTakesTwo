
UCLASS(NotBlueprintable, meta = ("HammerSmash (time marker)"))
class UAnimNotify_HammerSmash : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HammerSmash (time marker)";
	}
};