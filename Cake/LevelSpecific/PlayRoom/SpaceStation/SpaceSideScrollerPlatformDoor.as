
UCLASS(Abstract)
class ASpaceSideScrollerPlatformDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = DoorMesh)
	UHazeAkComponent HazeAkCompDoor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorOpenAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorCloseAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CloseDoorTimeLike;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CloseDoorTimeLike.BindUpdate(this, n"UpdateCloseDoor");
		CloseDoorTimeLike.BindFinished(this, n"FinishCloseDoor");
	}

	UFUNCTION()
	void ForceCloseDoor()
	{
		DoorRoot.SetRelativeLocation(EndLocation);
	}

	void OpenDoor()
	{
		CloseDoorTimeLike.Reverse();
		HazeAkCompDoor.HazePostEvent(DoorOpenAudioEvent);
	}

	void CloseDoor()
	{
		CloseDoorTimeLike.Play();
		HazeAkCompDoor.HazePostEvent(DoorCloseAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateCloseDoor(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, EndLocation, CurValue);
		DoorRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishCloseDoor()
	{

	}
}