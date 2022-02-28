UCLASS(NotBlueprintable, meta = ("ShowDrill"))
class UAnimNotify_ShowDrill : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "ShowDrill";
	}
};