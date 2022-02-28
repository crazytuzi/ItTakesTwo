import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;

UCLASS(Abstract)
class ADirtBag : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BagMesh;

	UPROPERTY(DefaultComponent)
	USickleCuttableComponent SickleCuttableComp;

	bool bDestroyed = false;

	UPROPERTY()
	AActor ConnectedActor;
	FVector ConnectedActorTargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"CutWithSickle");
		if (ConnectedActor != nullptr)
			ConnectedActorTargetLoc = ConnectedActor.ActorLocation - FVector(0.f, 0.f, 1000.f);
	}

	UFUNCTION()
	void CutWithSickle(int DamageAmount)
	{
		if (!bDestroyed)
		{
			bDestroyed = true;
			BP_CutWithSickle();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_CutWithSickle()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDestroyed)
		{
			FVector CurLocation = FMath::VInterpConstantTo(BagMesh.RelativeLocation, FVector(0.f, 0.f, 1000.f), DeltaTime, 250.f);
			BagMesh.SetRelativeLocation(CurLocation);
			
			if(ConnectedActor != nullptr)
			{		
				FVector CurConnectedActorLocation = FMath::VInterpConstantTo(ConnectedActor.ActorLocation, ConnectedActorTargetLoc, DeltaTime, 250.f);
				ConnectedActor.SetActorLocation(CurConnectedActorLocation);
			}
		}
	}
}