
UCLASS(NotBlueprintable, meta = ("SickleAttach"))
class UAnimNotify_SickleAttach : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SickleAttach";
	}

};

UCLASS(NotBlueprintable, meta = ("SickleDetach"))
class UAnimNotify_SickleDetach : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SickleDetach";
	}
};