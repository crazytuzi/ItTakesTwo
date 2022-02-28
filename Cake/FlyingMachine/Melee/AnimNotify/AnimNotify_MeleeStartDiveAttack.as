
UCLASS(NotBlueprintable, meta = ("_MeleeStartDiveAttack (time marker)"))
class UAnimNotify_MeleeStartDiveAttack : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "_MeleeStartDiveAttack (time marker)";
	}
};