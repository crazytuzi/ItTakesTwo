
UCLASS(NotBlueprintable, meta = ("Swarm Attack Performed (time marker)"))
class UAnimNotify_SwarmAttackPerformed : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Swarm Attack performed (time marker)";
	}
};