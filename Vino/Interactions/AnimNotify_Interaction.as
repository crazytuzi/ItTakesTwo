UCLASS(NotBlueprintable, meta = ("Interaction"))
class UAnimNotify_Interaction : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Interaction";
	}
};