import Cake.LevelSpecific.Hopscotch.MarbleMazeMouse;
import Cake.LevelSpecific.Hopscotch.MarbleMazeMouseCable;
class MarbleMazeMouseDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = DoorMesh)
	UStaticMeshComponent KnotMesh;
	
	UPROPERTY(DefaultComponent, Attach = DoorMesh)
	USceneComponent CableAttachComp;

	UPROPERTY()
	AMarbleMazeMouseCable ConnectedCableActor;

	UPROPERTY()
	AMarbleMazeMouse MarbleMazeMouse;

	bool bDoorMouseCheckDisabled = false;

	FVector MarbleMazeInitialLoc;

	float MouseDistance = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConnectedCableActor.AttachToComponent(CableAttachComp, n"", EAttachmentRule::SnapToTarget);
		MarbleMazeInitialLoc = MarbleMazeMouse.GetActorLocation();
	}

	UFUNCTION()
	void SetMouseCheckDisabled()
	{
		bDoorMouseCheckDisabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDoorMouseCheckDisabled)
			return;

		MouseDistance = (MarbleMazeMouse.GetActorLocation() - MarbleMazeInitialLoc).Size();
		MeshRoot.SetRelativeRotation(FRotator(FMath::GetMappedRangeValueClamped(FVector2D(0.f, 833.f), FVector2D(0.f, -25.f), MouseDistance), 0.f, 0.f)	);
	}
}