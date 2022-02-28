import Cake.LevelSpecific.Shed.Vacuum.VacuumableComponent;

event void FOnStartVacuumingActor(USceneComponent Nozzle);
event void FOnEndVacuumingActor();
event void FOnTickVacuumingActor(FVector VacuumDirection);

class AVacuumableActor : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent Collision;

    UPROPERTY(DefaultComponent)
    UVacuumableComponent VacuumableComponent;

    UPROPERTY()
    FOnStartVacuumingActor OnStartVacuumingActor;
    UPROPERTY()
    FOnEndVacuumingActor OnEndVacuumingActor;
    UPROPERTY()
    FOnTickVacuumingActor OnTickVacuumingActor;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        VacuumableComponent.OnStartVacuuming.AddUFunction(this, n"StartVacuuming");
        VacuumableComponent.OnEndVacuuming.AddUFunction(this, n"EndVacuuming");
    }

    UFUNCTION()
    void StartVacuuming(USceneComponent Nozzle)
    {
        OnStartVacuumingActor.Broadcast(Nozzle);
    }

    UFUNCTION()
    void EndVacuuming()
    {
        OnEndVacuumingActor.Broadcast();
    }

    UFUNCTION()
    void TickVacuuming(FVector Direction)
    {
        OnTickVacuumingActor.Broadcast(Direction);
    }
}