import Vino.Movement.Swinging.SwingPoint;

class AInteractiveBookPawn : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody; 
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TargetMoveLocationComponent;
	
	
	//FHazeAcceleratedVector AcceleratedVector;

	bool bMoveForward = false;
	bool bMoveBackwards = false;
	bool bPlayingSweetener = false;
	float SyncValue = 0;
	FVector StartPos;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SweetenerAudioEvent;

	// UPROPERTY()
	// float ForwardSpeed = 15;
	// UPROPERTY()
	// float BackwardsSpeed = 15;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPos = GetActorLocation();
		//AcceleratedVector.Value = StartPos;
	}

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaSeconds)
	// {
	// 	if(bMoveForward == true)
	// 	{
	// 		AcceleratedVector.SpringTo(TargetMoveLocationComponent.GetWorldLocation(), ForwardSpeed, 1, DeltaSeconds);
	// 		MeshBody.SetWorldLocation(AcceleratedVector.Value);
	// 	}
	// 	else if(bMoveBackwards == true)
	// 	{
	// 		AcceleratedVector.SpringTo(StartPos, BackwardsSpeed, 1, DeltaSeconds);
	// 		MeshBody.SetWorldLocation(AcceleratedVector.Value);
	// 	}
	// }

	void SetMoveCurrentMoveAmount(float NewAmount)
	{
		// Same value
		if(FMath::Abs(NewAmount - SyncValue) < KINDA_SMALL_NUMBER)
			return;

		if(NewAmount > SyncValue)
			MoveForwards();
		else
			MoveBackwards();

		SyncValue = NewAmount;
		FVector WantedLocation = FMath::Lerp(StartPos, TargetMoveLocationComponent.GetWorldLocation(), SyncValue);
		MeshBody.SetWorldLocation(WantedLocation);
	}

	UFUNCTION()
	void MoveForwards()
	{
		if(!bMoveForward)
		{
			bMoveForward = true;
			bMoveBackwards = false;
			UHazeAkComponent::HazePostEventFireForget(SweetenerAudioEvent, GetActorTransform());
		}

	}

	UFUNCTION()
	void MoveBackwards()
	{
		if(!bMoveBackwards && !bPlayingSweetener)
		{
			bMoveForward = false;
			bMoveBackwards = true;
			UHazeAkComponent::HazePostEventFireForget(SweetenerAudioEvent, GetActorTransform());
		}
	}
}

