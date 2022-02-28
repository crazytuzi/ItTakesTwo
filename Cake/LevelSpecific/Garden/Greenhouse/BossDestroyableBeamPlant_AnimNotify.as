UCLASS(NotBlueprintable, meta = ("JoySproutEnterFinish (time marker)"))
class UAnimNotify_JoySproutEnterFinish : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "JoySproutEnterFinish (time marker)";
	}
};