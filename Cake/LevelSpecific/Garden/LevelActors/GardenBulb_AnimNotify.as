UCLASS(NotBlueprintable, meta = ("BulbFinishedDying (time marker)"))
class UAnimNotify_BulbFinishedDying : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BulbFinishedDying (time marker)";
	}
}

UCLASS(NotBlueprintable, meta = ("BulbDyingRemoveWalkableCollision (time marker)"))
class UAnimNotify_BulbDyingRemoveWalkableCollision : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BulbDyingRemoveWalkableCollision (time marker)";
	}
}