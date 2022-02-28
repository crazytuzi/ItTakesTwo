import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;

UCLASS(NotBlueprintable, meta = ("FearBossBatSpawn (time marker)"))
class UAnimNotify_FearBossBatSpawn : UAnimNotify 
{

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FearBossBatSpawn (time marker)";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		ABasementBoss FearBoss = Cast<ABasementBoss>(MeshComp.GetOwner());
		if(FearBoss != nullptr)
		{
			// FearBoss.SpawnBat();
			return true;
		}

		return false;
	}
};