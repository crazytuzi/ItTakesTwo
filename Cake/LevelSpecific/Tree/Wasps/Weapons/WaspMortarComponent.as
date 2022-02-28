import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspShell;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspSpawnPoolComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;

class UWaspMortarComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AHazeActor> ShellClass = AWaspShell::StaticClass();

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	UWaspSpawnPoolComponent ShellPool;

	// Bound in construction script
	UPROPERTY(NotVisible, BlueprintReadWrite)
	USkinnedMeshComponent Mesh = nullptr;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		ShellPool = WaspSpawnPoolStatics::GetOrCreateSpawnPool(ShellClass, Owner);
		ensure(ShellPool.SpawnClass.Get() == ShellClass.Get());
	}

	AWaspShell GetShell()
	{
		if (!HasControl())
			return nullptr;

		FWaspSpawnParameters Params;
		Params.Location = Owner.ActorLocation;
		Params.Rotation = Owner.ActorRotation; 
		AWaspShell WaspShell = Cast<AWaspShell>(ShellPool.SpawnWasp(Owner, Params));
		return WaspShell;
	}

	FVector GetMuzzleLocation()
	{
		return Mesh.GetSocketLocation(n"Jaw");
	}

}