import Cake.FlyingMachine.FlyingMachine;

UCLASS(HideCategories = "Input Actor Replication Tick Cooking Mobile Physics Collision Lightning Rendering LOD")
class AFlyingMachineMeleeNut : AHazeActor
{   
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent Model;
	default Model.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = "Model", Category = "Activation")
	UNiagaraComponent ActivationEffect;

	UPROPERTY(Category = "Activation")
	float ShowModelAfterActivationEffectDelay = 0.2f;

	UPROPERTY(Category = "Impact")
	UHazeMeleeImpactAsset MovingImpactAsset;

	UPROPERTY(Category = "Impact")
	UNiagaraSystem DeactivationEffect;

	AFlyingMachine Airplane;
	bool bIsAttached = true;
	FVector LastRelativeLocation;
	float MoveTime = 0;
	bool bHasImpactedWithTarget = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"FlyingMachineMeleeNutMoveCapability");
		ActivationEffect.Deactivate();
		Model.SetHiddenInGame(true);
		ActivationEffect.SetHiddenInGame(true);
	}

	UFUNCTION()
	UStaticMeshComponent GetNutMesh()const
	{
		return Model;
	}

	void SpawnDestroyEffect()
	{
		if(Airplane == nullptr)
		{
			TArray<AFlyingMachine> AllAirplanes;
			GetAllActorsOfClass(AllAirplanes);
			Airplane = AllAirplanes[0];
		}

		if(Airplane == nullptr)
			return;

		Niagara::SpawnSystemAttached(
			DeactivationEffect, 
			Airplane.RootComponent, 
			NAME_None, 
			GetActorLocation(), 
			GetActorRotation(),
			EAttachLocation::KeepWorldPosition,
			true);
	}
}