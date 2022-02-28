import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Crusher.CastleEnemyBreakableWall;

class ACastleCrusherBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BridgeRoot;
	
	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	UHazeSkeletalMeshComponentBase SkeleMesh;

	UPROPERTY(DefaultComponent, Attach = SkeleMesh)
	UStaticMeshComponent BridgeMesh;

	UPROPERTY()
	TArray<ACastleEnemyBreakableWall> BridgeSupports;

	UPROPERTY(BlueprintReadOnly)
	bool bBridgeWeakened = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ACastleEnemyBreakableWall BridgeSupport : BridgeSupports)
		{	
			BridgeSupport.OnKilled.AddUFunction(this, n"OnSupportKilled");
		}		
	}

	UFUNCTION()
	void OnSupportKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		ACastleEnemyBreakableWall Support = Cast<ACastleEnemyBreakableWall>(Enemy);
		if (Support == nullptr)
			return;

		BridgeSupports.Remove(Support);

		if (BridgeSupports.Num() <= 0)
			BridgeWeakened();
	}

	void BridgeWeakened()
	{
		bBridgeWeakened = true;
	}
}