import Cake.FlyingMachine.FlyingMachine;

class AEscapeClosingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent UpperStaticMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LowerStaticMesh;
	
	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.RelativeLocation = FVector(-950.f, 0.f, 0.f);
	default Collision.BoxExtent = FVector(445.f, 5650.f, 3000.f);
	default Collision.CollisionProfileName = n"Trigger";

	UPROPERTY()
	AFlyingMachine FlyingMachine;

	UPROPERTY()
	bool bCloseDoor = false;

	UPROPERTY()
	float FarDistance = 30000.f;

	UPROPERTY()
	float NearDistance = 1000.f;

	UPROPERTY()
	float OpenOffset = 6000.f;

	UPROPERTY()
	float ClosedOffset = 1200.f;

	private bool bIsOverlapping = false;
	private bool bHasEnteredRange = false;
	private bool bHasClosedDoor = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Set doors to open initially
		UpperStaticMesh.SetRelativeLocation(FVector(0.f, 0.f, OpenOffset));
		LowerStaticMesh.SetRelativeLocation(FVector(0.f, 0.f, -OpenOffset));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float DistanceSqr = (FlyingMachine.ActorLocation - ActorLocation).SizeSquared();
		float FarDistanceSqr = FMath::Square(FarDistance);
		float NearDistanceSqr = FMath::Square(NearDistance);
	
		if (DistanceSqr >= FarDistanceSqr)
		{
			// Tick slowly until we're close enough
			SetActorTickInterval(1.f);
			return;
		}
		else
		{
			// We have to tick every frame since the door mesh will be offset based on distance
			SetActorTickInterval(0.f);
		}

		if (!bHasEnteredRange)
		{
			bHasEnteredRange = true;
			BP_DoorStartClosing();
		}

		if (!bHasClosedDoor)
		{
			float DistanceAlpha = FMath::Clamp(DistanceSqr / (FarDistanceSqr - NearDistanceSqr), 0.f, 1.f);
			float ZOffset = bCloseDoor ? FMath::FInterpConstantTo(UpperStaticMesh.RelativeLocation.Z, 0.f, DeltaTime, 500.f) :
				FMath::Lerp(ClosedOffset, OpenOffset, DistanceAlpha);

			UpperStaticMesh.SetRelativeLocation(FVector(0.f, 0.f, ZOffset));
			LowerStaticMesh.SetRelativeLocation(FVector(0.f, 0.f, -ZOffset));

			// Stop ticking when we've closed the door
			// could potentially mean that end overlap never gets called
			// but it's unused, so we should be good
			if (FMath::IsNearlyZero(ZOffset))
			{
				bHasClosedDoor = true;
				// Print("DoorWasClosed", 100.f);
				BP_DoorClosed();
				SetActorTickEnabled(false);
			}
		}

		// Check for overlaps on control side
		if (HasControl())
		{
			bool bWasOverlapping = bIsOverlapping;
			bIsOverlapping = Trace::ComponentOverlapComponent(
				FlyingMachine.Mesh, 
				Collision, 
				Collision.WorldLocation,
				Collision.ComponentQuat, 
				bTraceComplex = false);

			if (bIsOverlapping && !bWasOverlapping)
				NetBeginOverlap();

			if (!bIsOverlapping && bWasOverlapping)
				NetEndOverlap();
		}
	}

	UFUNCTION()
	void DisableDoor()
	{
		bHasClosedDoor = true;
		UpperStaticMesh.SetRelativeLocation(FVector(0.f, 0.f, 0.f));
		LowerStaticMesh.SetRelativeLocation(FVector(0.f, 0.f, 0.f));		
	}

	UFUNCTION(NetFunction)
	private void NetBeginOverlap()
	{
		Collision.TriggerMutualBeginOverlap(FlyingMachine.Mesh);
	}

	UFUNCTION(NetFunction)
	private void NetEndOverlap()
	{
		Collision.TriggerMutualEndOverlap(FlyingMachine.Mesh);
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_DoorStartClosing()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_DoorClosed()
	{}
}