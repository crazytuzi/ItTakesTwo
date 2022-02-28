import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class ARollingGumball : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UStaticMeshComponent GumBallMesh;

    UHazeMovementComponent Movement;
    
    default SetActorScale3D(FVector(3.f, 3.f, 3.f));
    default GumBallMesh.SetSimulatePhysics(true);
    default InitialLifeSpan = 90.f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        GumBallMesh.OnComponentHit.AddUFunction(this, n"OnGumballHit");
    }

    UFUNCTION()
    void OnGumballHit(UPrimitiveComponent HitComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, FVector NormalImpulse, FHitResult& Hit)
    {
        AHazePlayerCharacter Player;
        Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player != nullptr)
        {
            if (Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
            {
                DestroyActor();
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick (float Delta)
    {

    }
}