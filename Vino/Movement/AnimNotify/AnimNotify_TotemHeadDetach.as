
UCLASS(NotBlueprintable, meta = ("TotemHeadDetach (time marker)"))
class UAnimNotify_TotemHeadDetach : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TotemHeadDetach (time marker)";
	}
};