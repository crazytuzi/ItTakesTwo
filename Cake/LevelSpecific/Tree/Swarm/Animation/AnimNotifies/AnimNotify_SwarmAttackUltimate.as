
UCLASS(NotBlueprintable, meta = ("Swarm Ulti Attack (time marker)"))
class UAnimNotify_SwarmAttackUltimate : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Swarm Ulti Attack (time marker)";
	}
};