UCLASS(NotBlueprintable, meta = ("IceSkatingWindow (time marker)"))
class UAnimNotify_IceSkatingWindow : UAnimNotify
{
	UPROPERTY(Category = "IceSkating")
	bool bRightFoot = false;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "IceSkatingWindow (time marker)";
	}
}