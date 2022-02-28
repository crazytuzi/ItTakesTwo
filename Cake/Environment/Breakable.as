import Cake.Environment.BreakableComponent;

UCLASS(hidecategories="Physics Collision Rendering Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class ABreakableActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UBreakableComponent BreakableComponent;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		BreakableComponent.ConstructionScript_Hack();
    }

	UFUNCTION(BlueprintCallable)
	void DisableAllCollision()
	{
		TArray<UPrimitiveComponent> Prims;
		GetComponentsByClass(Prims);
		for(UPrimitiveComponent IterPrim : Prims)
		{
			IterPrim.CollisionEnabled = ECollisionEnabled::NoCollision;
			IterPrim.SetCollisionProfileName(n"NoCollision");
			IterPrim.SetGenerateOverlapEvents(false);
		}
		SetActorEnableCollision(false);
	}
}