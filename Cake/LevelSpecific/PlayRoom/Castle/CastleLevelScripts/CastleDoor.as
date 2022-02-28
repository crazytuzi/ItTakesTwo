class ACastleDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;	

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorPivot;

	UPROPERTY(DefaultComponent, Attach = DoorPivot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorOpenAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorCloseAudioEvent;

	UPROPERTY()
	float RotationDegrees = -100.f;
	float StartYaw;

	UPROPERTY()
	bool bStartOpen = false;

	UPROPERTY()
	FHazeTimeLike DoorMovement;
	default DoorMovement.Duration = 1.f;

	UPROPERTY()
	float StartTime;
	

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif	

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bStartOpen)
		{
			FRotator NewRotation = FRotator(DoorPivot.RelativeRotation.Pitch, RotationDegrees, DoorPivot.RelativeRotation.Roll);
			DoorPivot.SetRelativeRotation(NewRotation);
			StartTime = DoorMovement.Duration;
		}
		else
		{
			DoorPivot.SetRelativeRotation(FRotator::ZeroRotator);
			StartTime = 0;			
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorMovement.BindUpdate(this, n"OnDoorMovementUpdate");	
		DoorMovement.SetNewTime(StartTime);
	}

	UFUNCTION(DevFunction)
	void OpenDoor()
	{
		DoorMovement.Play();
		UHazeAkComponent::HazePostEventFireForget(DoorOpenAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(DevFunction)
	void CloseDoor()
	{
		DoorMovement.Reverse();
		UHazeAkComponent::HazePostEventFireForget(DoorCloseAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void OnDoorMovementUpdate(float CurrentValue)
	{
		float NewYaw = FMath::Lerp(0.f, RotationDegrees, CurrentValue);
		FRotator NewRotation = FRotator(DoorPivot.RelativeRotation.Pitch, NewYaw, DoorPivot.RelativeRotation.Roll);

		DoorPivot.SetRelativeRotation(NewRotation);
	}
}