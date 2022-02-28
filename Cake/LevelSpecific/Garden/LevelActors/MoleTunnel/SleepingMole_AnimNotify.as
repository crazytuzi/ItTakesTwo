UCLASS(NotBlueprintable, meta = ("MoleSleepRollFinished (time marker)"))
class UAnimNotify_SleepingMoleRoll : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "MoleSleepRollFinished (time marker)";
	}
};