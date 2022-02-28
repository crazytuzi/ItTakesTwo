UCLASS(Abstract)
class AMusicDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;

	UPROPERTY()
	bool bPreviewEnd;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveDoorTimeLike;
	default MoveDoorTimeLike.Duration = 0.5f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEnd)
			DoorRoot.SetRelativeLocation(EndLocation);
		else
			DoorRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveDoorTimeLike.BindUpdate(this, n"UpdateMoveDoor");
		MoveDoorTimeLike.BindFinished(this, n"FinishMoveDoor");
	}

	UFUNCTION()
	void OpenDoor()
	{
		MoveDoorTimeLike.Play();
	}

	UFUNCTION()
	void CloseDoor()
	{
		MoveDoorTimeLike.Reverse();
	}

	UFUNCTION()
	void UpdateMoveDoor(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, EndLocation, CurValue);
		DoorRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION()
	void FinishMoveDoor()
	{

	}
}