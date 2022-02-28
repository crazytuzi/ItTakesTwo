
import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.MagneticMoveableObjectConstrained;

UCLASS(Abstract)
class AGiftDispenserActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpawnLocation;

	bool bCompletedGift;

	UPROPERTY()
	TSubclassOf<AHazeActor> GiftClass;

	UPROPERTY()
	TArray<AMagneticMoveableObjectConstrained> Levers;

	TArray<bool> LeversReachedEnd;

	UPROPERTY()
	AHazeActor Gift;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Levers.Num() > 0)
		{
			for(AMagneticMoveableObjectConstrained Lever : Levers)
			{
				LeversReachedEnd.Add(Lever.bReachedEnd);
				Lever.OnMoveableObjectReachedEnd.AddUFunction(this, n"LeverMoved");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}

	UFUNCTION()
	void LeverMoved(bool ReachedEnd, AMagneticMoveableObjectConstrained Object)
	{
		int Index = Levers.FindIndex(Object);
		LeversReachedEnd[Index] = ReachedEnd;

		for(bool LeverReachedEnd : LeversReachedEnd)
		{
			if(!LeverReachedEnd)
				return;
		}

		SpawnGift();			
	}

	UFUNCTION()
	void SpawnGift()
	{
		if (!bCompletedGift)
		{
			if(Gift == nullptr)
			{
				Gift = Cast<AHazeActor>(SpawnActor(GiftClass, SpawnLocation.WorldLocation, SpawnLocation.WorldRotation, bDeferredSpawn = true));
        		Gift.MakeNetworked(this);
				FinishSpawningActor(Gift);
			}
			else
			{
				if (this.HasControl())
				{
					NetResetGift();
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetResetGift()
	{
		Gift.SetActorRotation(SpawnLocation.WorldRotation);			
	}

	UFUNCTION()
	void CompletedGift()
	{
		bCompletedGift = true;
	}
}