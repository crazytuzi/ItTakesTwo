import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;
import Cake.LevelSpecific.Clockwork.SplineBoat.TunnelRideDoors;

class ATunnelRideDoorTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DoorTrigger;
	default DoorTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY()
	ATunnelRideDoors TunnelDoors;

	UPROPERTY()
	bool bCanOpen;

	UPROPERTY()
	bool bIsSlowSpeed;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		DoorTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		// ASplineBoatActor Boat = Cast<ASplineBoatActor>(OtherActor);

		// Print("" + Boat.Name, 10.f);

		// if (Boat == nullptr)
		// 	return;

		// Boat.SetIsSlowSpeed(bIsSlowSpeed);

		// Print("Boat NOT NULL", 10.f);
		
		// if (TunnelDoors == nullptr)
		// 	return;

		// TunnelDoors.ActivateDoors(bCanOpen);
    }
}