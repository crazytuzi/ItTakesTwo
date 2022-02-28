import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceTinyElevatorTopHatch;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

class ASpaceTinyElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UStaticMeshComponent ElevatorMesh;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UBoxComponent EntryTrigger;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UBoxComponent ExitTrigger;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UBoxComponent EntranceBlocker;

	UPROPERTY(DefaultComponent, Attach = ElevatorMesh)
	UHazeAkComponent HazeAkCompElevator;

	UPROPERTY(DefaultComponent, Attach = DoorMesh)
	UHazeAkComponent HazeAkCompDoor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElevatorMoveUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElevatorMoveDownAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorOpenAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorCloseAudioEvent;

	UPROPERTY(meta = (MakeEditWidget))
	FVector TopLocation;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveElevatorTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveDoorTimeLike;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY()
	ASpaceTinyElevatorTopHatch TopHatch;

	bool bAtBottom = true;
	bool bAtTop = false;

	bool bDoorClosing = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EntryTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterElevator");
		ExitTrigger.OnComponentBeginOverlap.AddUFunction(this, n"ExitElevator");

		MoveElevatorTimeLike.BindUpdate(this, n"UpdateMoveElevator");
		MoveElevatorTimeLike.BindFinished(this, n"FinishMoveElevator");

		MoveDoorTimeLike.SetPlayRate(2.25f);
		MoveDoorTimeLike.BindUpdate(this, n"UpdateMoveDoor");
		MoveDoorTimeLike.BindFinished(this, n"FinishMoveDoor");
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterElevator(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!bAtBottom)
			return;

		if (MoveElevatorTimeLike.IsPlaying())
			return;

		CloseDoor();
		Player.BlockCapabilities(MovementSystemTags::Jump, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitElevator(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!bAtTop)
			return;

		if (MoveElevatorTimeLike.IsPlaying())
			return;

		CloseDoor();
		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
	}

	void CloseDoor()
	{
		SetDoorCollisionStatus(false);
		bDoorClosing = true;
		SetEntranceBlockerStatus(true);
		MoveDoorTimeLike.PlayFromStart();

		HazeAkCompDoor.HazePostEvent(DoorCloseAudioEvent);
	}
	
	void MoveElevator()
	{
		if (bAtBottom)
		{
			MoveElevatorTimeLike.PlayFromStart();
			OpenHatch();
			HazeAkCompElevator.HazePostEvent(ElevatorMoveUpAudioEvent);
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationElevatorConductor");
		}
		else
		{
			MoveElevatorTimeLike.ReverseFromEnd();
			System::SetTimer(this, n"CloseHatch", 1.35f, false);
			HazeAkCompElevator.HazePostEvent(ElevatorMoveDownAudioEvent);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OpenHatch()
	{
		TopHatch.OpenHatch();
	}

	UFUNCTION(NotBlueprintCallable)
	void CloseHatch()
	{
		TopHatch.CloseHatch();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveElevator(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, TopLocation, CurValue);
		ElevatorRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveElevator()
	{
		if (bAtBottom)
		{
			bAtTop = true;
			bAtBottom = false;
			MoveDoorTimeLike.ReverseFromEnd();
		}
		else
		{
			bAtTop = false;
			bAtBottom = true;
			MoveDoorTimeLike.ReverseFromEnd();
		}

		SetDoorCollisionStatus(true);
		SetEntranceBlockerStatus(false);
		HazeAkCompDoor.HazePostEvent(DoorOpenAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveDoor(float CurValue)
	{
		float CurRot = FMath::Lerp(90.f, 0.f, CurValue);
		DoorRoot.SetRelativeRotation(FRotator(0.f, 0.f, CurRot));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveDoor()
	{
		if (bDoorClosing)
		{
			MoveElevator();
			bDoorClosing = false;
		}
	}

	void SetEntranceBlockerStatus(bool bBlocking)
	{
		if (bBlocking)
			EntranceBlocker.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		else
			EntranceBlocker.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	void SetDoorCollisionStatus(bool bBlocking)
	{
		if (bBlocking)
			DoorMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		else
			DoorMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
}