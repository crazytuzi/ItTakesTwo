import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;

UCLASS(NotBlueprintable, meta = ("FearBossShadowWallSpawn (time marker)"))
class UAnimNotify_FearBossShadowWallSpawn : UAnimNotify 
{

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FearBossShadowWallSpawn (time marker)";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		ABasementBoss FearBoss = Cast<ABasementBoss>(MeshComp.GetOwner());
		if(FearBoss != nullptr)
		{
			FearBoss.SpawnShadowWall();
			return true;
		}

		return false;
	}
};