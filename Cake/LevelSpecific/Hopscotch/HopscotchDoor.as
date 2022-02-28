class AHopscotchDoor : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

    UPROPERTY(DefaultComponent, Attach = MeshRoot)
    UStaticMeshComponent DoorMesh;
    default DoorMesh.RelativeLocation = FVector(0.f, 0.f, 437.f);
    default DoorMesh.RelativeScale3D = FVector(1.25f, 4.25f, 8.75f);

    UPROPERTY(DefaultComponent, Attach = DoorMesh)
    UBoxComponent BlockingBox;
    default BlockingBox.BoxExtent = FVector(63.f, 210.f, 437.f);
    default BlockingBox.RelativeLocation = FVector(0.f, 0.f, 437.f);
    default BlockingBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

    UPROPERTY()
    FHazeTimeLike DoorTimeline;
    default DoorTimeline.Duration = 1.f;

    UPROPERTY()
    bool bStartOpen;
    default bStartOpen = false;

    FVector OpenDoorLocation;
    FVector ClosedDoorLocation;

	FRotator InitialRotation;
	FRotator TargetRotation;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        DoorTimeline.BindUpdate(this, n"DoorTimelineUpdate");
        ClosedDoorLocation = DoorMesh.GetRelativeTransform().Location;
        OpenDoorLocation = FVector(ClosedDoorLocation.X, ClosedDoorLocation.Y, -ClosedDoorLocation.Z);

		InitialRotation = MeshRoot.RelativeRotation;
		TargetRotation = FRotator(MeshRoot.RelativeRotation + FRotator(90.f, 0.f, 0.f));

        if (bStartOpen)
        {
            DoorMesh.SetRelativeLocation(OpenDoorLocation); 
            BlockingBox.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        }
    }

    UFUNCTION()
    void DoorTimelineUpdate(float CurrentValue)
    {
        MeshRoot.SetRelativeRotation(QuatLerp(InitialRotation, TargetRotation, CurrentValue));
    }

    UFUNCTION()
    void OpenDoor()
    {
        DoorTimeline.PlayFromStart();
        BlockingBox.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }

    UFUNCTION()
    void CloseDoor()
    {
        DoorTimeline.ReverseFromEnd();
        BlockingBox.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    }

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}