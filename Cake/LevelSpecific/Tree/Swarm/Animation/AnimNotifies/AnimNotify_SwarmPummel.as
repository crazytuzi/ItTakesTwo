
UCLASS(NotBlueprintable, meta = ("Swarm Pummel Attack (time marker)"))
class UAnimNotify_SwarmPummel : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Swarm Pummel Attack (time marker)";
	}
};