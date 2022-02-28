import Cake.LevelSpecific.Hopscotch.RollingGumball;

class AGumballSpawner : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UBillboardComponent Root;

    UPROPERTY()
    float SpawnInterval;

    UPROPERTY(EditDefaultsOnly)
    TSubclassOf<ARollingGumball> ClassToSpawn;
    
    default SpawnInterval = 5.f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        System::SetTimer(this, n"SpawnGumball", SpawnInterval, bLooping = true);
    }

    UFUNCTION()
    void SpawnGumball()
    {       
        SpawnActor(ClassToSpawn, GetActorLocation());
    }
}