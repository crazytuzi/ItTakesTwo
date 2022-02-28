UCLASS(NotBlueprintable, meta = ("JoyHammerSmash (time marker)"))
class UAnimNotify_JoyHammerSmash : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "JoyHammerSmash (time marker)";
	}
};