
class AHorseDerbyObstacleDoors : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot1;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot2;

	UPROPERTY(DefaultComponent, Attach = DoorRoot1)
	UStaticMeshComponent DoorMesh1;

	UPROPERTY(DefaultComponent, Attach = DoorRoot2)
	UStaticMeshComponent DoorMesh2;

	//Flips Scale/RotationDirections of doors.
	UPROPERTY(Category = "Settings")
	bool bLeftSideDoors = false;

	UPROPERTY(Category = "Settings")
	float EndYawRotation = 90.f;

	UPROPERTY(Category = "Settings")
	FHazeTimeLike DoorOpenTimeLike;

	FRotator DefaultRotationDoor1;
	FRotator DefaultRotationDoor2;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bLeftSideDoors)
		{
			DoorMesh1.RelativeScale3D = FVector(-1.f, 1.f, 1.f);
			DoorMesh2.RelativeScale3D = FVector(-1.f, 1.f, 1.f);
		}
		DoorMesh1.SetCullDistance(Editor::GetDefaultCullingDistance(DoorMesh1) * CullDistanceMultiplier);
		DoorMesh2.SetCullDistance(Editor::GetDefaultCullingDistance(DoorMesh2) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorOpenTimeLike.BindUpdate(this, n"DoorTimeLikeUpdate");
		DoorOpenTimeLike.BindFinished(this, n"DoorTimeLikeFinish");

		DefaultRotationDoor1 = DoorRoot1.RelativeRotation;
		DefaultRotationDoor2 = DoorRoot2.RelativeRotation;
	}

	void OpenDoors()
	{
		DoorOpenTimeLike.Play();
	}

	void CloseDoors()
	{
		DoorOpenTimeLike.Reverse();
	}

	UFUNCTION()
	void DoorTimeLikeUpdate(float CurrentValue)
	{
		FRotator NewRotation1;
		FRotator NewRotation2;

			if(bLeftSideDoors)
			{
				NewRotation1 = FRotator(DefaultRotationDoor1.Pitch, DefaultRotationDoor1.Yaw + (CurrentValue * EndYawRotation), DefaultRotationDoor1.Roll);
				NewRotation2 = FRotator(DefaultRotationDoor2.Pitch, DefaultRotationDoor2.Yaw - (CurrentValue * EndYawRotation), DefaultRotationDoor2.Roll);
			}
			else
			{
				NewRotation1 = FRotator(DefaultRotationDoor1.Pitch, DefaultRotationDoor1.Yaw - (CurrentValue * EndYawRotation), DefaultRotationDoor1.Roll);
				NewRotation2 = FRotator(DefaultRotationDoor2.Pitch, DefaultRotationDoor2.Yaw + (CurrentValue * EndYawRotation), DefaultRotationDoor2.Roll);
			}

		DoorRoot1.SetRelativeRotation(NewRotation1);
		DoorRoot2.SetRelativeRotation(NewRotation2);
	}

	UFUNCTION()
	void DoorTimeLikeFinish()
	{

	}
}