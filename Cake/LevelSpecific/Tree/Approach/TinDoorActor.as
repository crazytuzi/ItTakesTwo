import Cake.LevelSpecific.Tree.Approach.DoubleHangActor;
event void FOnDoorOpen();
class ATindoorActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent MeshToMove;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DesiredPosition;

	UPROPERTY()
	ADoubleHangActor HangActor;

	UPROPERTY()
	FOnDoorOpen OnDoorOpen;

	FRotator StartRotation;
	FRotator EndRotation;

	bool bDoorWasOpened = false;
	bool bStopMovingDoor = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = ActorRotation;
		EndRotation = DesiredPosition.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bStopMovingDoor == false)
			ActorRotation = FMath::LerpShortestPath(StartRotation, EndRotation, HangActor.Percentage/10);

	/*
		if(HangActor.Percentage >= 0.95)
		{
			if(bDoorWasOpened == true)
				return;

			bDoorWasOpened = true;
			DoorWasOpened();
		}
	*/
	}

	UFUNCTION()
	void StopMovingDoor()
	{
		bStopMovingDoor = true;
	}

	/*
	UFUNCTION()
	void DoorWasOpened()
	{
		if(HasControl())
		{
			NetDoorWasOpened();
		}
	}
	UFUNCTION(NetFunction)
	void NetDoorWasOpened()
	{
		OnDoorOpen.Broadcast();
	}
	*/
}