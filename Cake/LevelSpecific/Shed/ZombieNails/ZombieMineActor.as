class AZombieMineActor : AHazeActor
{
    UPROPERTY()
    UStaticMeshComponent MineMesh;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {

    }

    UFUNCTION()
    void ActivateMine()
    {
        MineMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
        MineMesh.SetSimulatePhysics(true);
    }
}