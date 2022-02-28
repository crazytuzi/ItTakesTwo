UCLASS(NotBlueprintable, meta = ("CodyTakesOverJoyFinished (time marker)"))
class UAnimNotify_CodyTakesOverJoy : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "CodyTakesOverJoyFinished (time marker)";
	}
};