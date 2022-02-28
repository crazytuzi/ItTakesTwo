
UCLASS(NotBlueprintable, meta = ("Swarm Attack Started (time marker)"))
class UAnimNotify_SwarmAttackStarted : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Swarm Attack Started (time marker)";
	}
};