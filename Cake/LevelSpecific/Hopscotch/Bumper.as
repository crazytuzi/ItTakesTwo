import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.Helpers.BurstForceStatics;

event void FBumperEventSignature(ABumper Bumper, AHazePlayerCharacter Player);

class ABumper : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;
        
    UPROPERTY()
    TArray<UStaticMeshComponent> StaticMeshArray;

    UPROPERTY()
    FBumperEventSignature BumperEvent;
    
    UPROPERTY()
    float BumperSpeed = 5000.f;

    UPROPERTY()
    UStaticMesh BumperMesh;

    UPROPERTY(meta = (MakeEditWidget))
    TArray<FVector> BumperLocation;

    UPROPERTY()
    bool bBumpersShouldBeHidden;

    UHazeMovementComponent Movement;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        for (int i = 0; i < BumperLocation.Num(); i++)
        {
            UStaticMeshComponent Mesh = UStaticMeshComponent::Create(this);
            StaticMeshArray.Add(Mesh);

            Mesh.SetRelativeLocation(FVector(BumperLocation[i] + FVector(0,0,50)));
            Mesh.SetRelativeRotation(FRotator(0,0,-90));
            Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            Mesh.SetStaticMesh(BumperMesh);

            if (i == 0)
            {
                USphereComponent SphereCollision = USphereComponent::Create(this);
                SphereCollision.AttachToComponent(Mesh);
                SphereCollision.SphereRadius = 100.f;
                SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
            }
        }

        StaticMeshArray[StaticMeshArray.Num() - 1].SetHiddenInGame(true);

        if (bBumpersShouldBeHidden)
        {
            for (UStaticMeshComponent Mesh : StaticMeshArray)
            {
                Mesh.SetHiddenInGame(true);
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {

    }

    UFUNCTION(CallInEditor)
    void AddBumperLocation()
    {
        BumperLocation.Add(FVector::ZeroVector);
    }

    UFUNCTION(CallInEditor)
    void RemoveBumperLocation()
    {
        if (BumperLocation.Num() > 0)
        {
            BumperLocation.RemoveAt(BumperLocation.Num() - 1);
        }
    }

    UFUNCTION(CallInEditor)
    void RemoveAllBumperLocations()
    {
        if (BumperLocation.Num() > 0)
        {
            BumperLocation.Empty();
        }
    }

    UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {

        AHazePlayerCharacter Player;
        Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player != nullptr)
        {
            BumperEvent.Broadcast(this, Player);
            
        }
    }
}