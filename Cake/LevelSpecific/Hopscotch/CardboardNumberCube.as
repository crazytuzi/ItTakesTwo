import Cake.LevelSpecific.Hopscotch.NumberCube;
import Peanuts.Movement.SplineLockStatics;

class ACardboardNumberCube : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CardboardMesh;

	UPROPERTY(DefaultComponent, Attach = CardboardMesh)
	UBoxComponent PushPlayerCollision;
	default PushPlayerCollision.RelativeLocation = FVector(280.f, 0.f, 200.f);
	default PushPlayerCollision.BoxExtent = FVector(32.f, 200.f, 200.f);

	UPROPERTY(DefaultComponent, Attach = CardboardMesh)
	UStaticMeshComponent NumberMesh;
	default NumberMesh.RelativeLocation = FVector(300.f, 200.f, 400.f);
	default NumberMesh.RelativeRotation = FRotator(90.f, -180.f, -180.f);
	default NumberMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	FHazeTimeLike MoveCubeTimeline;
	default MoveCubeTimeline.Duration = 0.5f;
	default MoveCubeTimeline.bSyncOverNetwork = true;
	default MoveCubeTimeline.SyncTag = n"CardboardCubeTimeline";

	UPROPERTY()
	float MoveAmountInForwardVector;

	UPROPERTY()
	EHopScotchNumber HopscotchNumber;
	
	UPROPERTY()
	TArray<UMaterialInstance> MaterialArray;

	FVector InitialLocation;
	FVector TargetLocation;

	bool bMovingCubeForward;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveCubeTimeline.BindUpdate(this, n"MoveCubeTimelineUpdate");
		MoveCubeTimeline.BindFinished(this, n"MoveCubeTimelineFinished");
		PushPlayerCollision.OnComponentBeginOverlap.AddUFunction(this, n"PushPlayerCollisionBeginOverlap");

		InitialLocation = CardboardMesh.WorldLocation;
		TargetLocation = InitialLocation + (FVector(CardboardMesh.GetForwardVector() * MoveAmountInForwardVector));
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (MaterialArray.IsValidIndex(HopscotchNumber))
			NumberMesh.SetMaterial(0, MaterialArray[HopscotchNumber]);
	}
	
	UFUNCTION()
	void ActivateCube()
	{
		MoveCubeTimeline.Play();

		bMovingCubeForward = MoveAmountInForwardVector > 0 ? true : false;

		if (bMovingCubeForward)
			CardboardMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(NetFunction)
	void NetActivateCube()
	{
		ActivateCube();
		Print("HElo", 2.0f);
	}

	UFUNCTION(NetFunction)
	void NetDeactivateCube()
	{
		DeactivateCube();
	}
	
	UFUNCTION()
	void DeactivateCube()
	{
		MoveCubeTimeline.Reverse();

		bMovingCubeForward = MoveAmountInForwardVector > 0 ? false : true;

		if (bMovingCubeForward)
			CardboardMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void MoveCubeTimelineUpdate(float CurrentValue)
	{
		CardboardMesh.SetWorldLocation(FMath::VLerp(InitialLocation, TargetLocation, FVector(CurrentValue, CurrentValue, CurrentValue)));
		CardboardMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION()
	void MoveCubeTimelineFinished(float CurrentValue)
	{
		bMovingCubeForward = false;
	}

	UFUNCTION()
	void PushPlayerCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (bMovingCubeForward)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

			if (Player != nullptr)
			{
				StopSplineLockMovement(Player);
				Player.AddImpulse(FVector(CardboardMesh.GetForwardVector() * 500.f));
			}		
		}
	}
}