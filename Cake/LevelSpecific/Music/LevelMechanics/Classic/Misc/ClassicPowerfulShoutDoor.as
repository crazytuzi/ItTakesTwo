
class AClassicPowerfulShoutDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent DoorMesh;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothFloatSyncRotation;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent AccleratedFloatSync;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorOpenAudioEvent;


	FHazeAcceleratedFloat AcceleratedFloat;

	bool bPowerfulSongActive = false;
	bool bDoorActive = false;

	UPROPERTY()
	float RotateTargetValue = 30;
	UPROPERTY()
	bool bIsLeftDoor = true;
	bool bCompletedDoor = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::May);
		AccleratedFloatSync.OverrideControlSide(Game::GetMay());
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bDoorActive)
			return;

		if(Game::GetMay().HasControl())
		{
			TickMovement(DeltaSeconds);
			SmoothFloatSyncRotation.Value = DoorMesh.GetRelativeRotation();
			AccleratedFloatSync.Value = AcceleratedFloat.Value;
		}
		else
		{	
			AcceleratedFloat.Value = AccleratedFloatSync.Value;
			DoorMesh.SetRelativeRotation(FRotator(0, SmoothFloatSyncRotation.Value.Yaw, 0));
		}
	}

	UFUNCTION()
	void TickMovement(float DeltaSeconds)
	{
		if(bPowerfulSongActive)
		{
			AcceleratedFloat.SpringTo(RotateTargetValue, 20, 0.2f, DeltaSeconds);
			DoorMesh.SetRelativeRotation(FRotator(0, AcceleratedFloat.Value, 0));
		}
	}


	UFUNCTION()
	void PowerfulSongActivated()
	{
		bPowerfulSongActive = true;
		bCompletedDoor = true;
		System::SetTimer(this, n"PowerfulSongDisableDoorTimer", 5.f, false);
		UHazeAkComponent::HazePostEventFireForget(DoorOpenAudioEvent, this.GetActorTransform());
	}
	UFUNCTION()
	void PowerfulSongDisableDoorTimer()
	{
		bDoorActive = false;
	}


	UFUNCTION()
	void OpenDoorInstantly()
	{
		DoorMesh.SetRelativeRotation(FRotator(0, RotateTargetValue, 0));
		bDoorActive = false;
		bCompletedDoor = true;
	}
	UFUNCTION()
	void ActivateDoor()
	{
		if(!bCompletedDoor)
			bDoorActive = true;
	}
}

