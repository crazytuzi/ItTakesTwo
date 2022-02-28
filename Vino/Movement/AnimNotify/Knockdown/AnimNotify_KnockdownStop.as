// Triggered when you want knocked down character to come to a full stop, i.e. no further sliding from knockdown.
UCLASS(NotBlueprintable, meta = ("Knockdown Stop"))
class UAnimNotify_KnockdownStop : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Knockdown Stop";
	}
};