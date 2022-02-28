UCLASS(NotBlueprintable, meta = ("ClawCheckCaught (time marker)"))
class UAnimNotify_ClawCheckCaught : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "ClawCheckCaught (time marker)";
	}
};