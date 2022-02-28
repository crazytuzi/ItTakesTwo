UCLASS(NotBlueprintable, meta = ("HideDrill"))
class UAnimNotify_HideDrill : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HideDrill";
	}
};