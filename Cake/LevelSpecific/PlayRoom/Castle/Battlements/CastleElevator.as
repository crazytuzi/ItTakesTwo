import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleElevatorSwitch;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleElevatorSwitchPickupable;
import Vino.Pickups.PlayerPickupComponent;

class ACastleElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbVisualizeComponent(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	USceneComponent ElevatorGateRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	USceneComponent ElevatorFenceRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	USceneComponent GearBaseRoot;

	UPROPERTY(DefaultComponent, Attach = GearBaseRoot)
	UStaticMeshComponent GearMesh;
	default GearMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent AcceptanceRadius;
	default AcceptanceRadius.SphereRadius = 200.f;
	default AcceptanceRadius.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(meta = (MakeEditWidget))
	FVector ElevatorStop = FVector(0, 0, 2000);

	UPROPERTY()
	FVector StartLocation;	
	UPROPERTY()
	FVector EndLocation;
	
	UPROPERTY()
	float ElevatorProgress = 0.f;

	UPROPERTY()
	FHazeTimeLike ElevatorMovementTimelike;
	default ElevatorMovementTimelike.Duration = 8.0f;

	UPROPERTY()
	FHazeTimeLike ElevatorDoorTimelike;
	default ElevatorDoorTimelike.Duration = 0.6f;

	UPROPERTY()
	bool bGearPlacedInElevator = false;

	AHazePlayerCharacter OverlappingPlayer;

	/*UPROPERTY()
	TArray<FCastleElevatorSwitchWeight> ElevatorSwitches;
	float TotalSwitchWeight = 0.f;*/

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ElevatorRoot.RelativeLocation;
		EndLocation = StartLocation + ElevatorStop;

		ElevatorMovementTimelike.BindUpdate(this, n"OnElevatorMovementTimelikeUpdate");
		ElevatorMovementTimelike.BindFinished(this, n"OnElevatorMovementTimelikeFinished");

		ElevatorDoorTimelike.BindUpdate(this, n"OnElevatorDoorTimelikeUpdate");
		ElevatorDoorTimelike.BindFinished(this, n"OnElevatorDoorTimelikeFinished");

		SetControlSide(Game::GetMay());
	}
	
	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		if (!HasControl())
			return; 

		OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		if (OverlappingPlayer == nullptr)
			return;

		CheckIfPlayerIsHoldingElevatorSwitch(OverlappingPlayer);
    }

	void CheckIfPlayerIsHoldingElevatorSwitch(AHazePlayerCharacter Player)
	{
		if (bGearPlacedInElevator)
			return;

		UPlayerPickupComponent PickupComponent = UPlayerPickupComponent::Get(Player);
		if (PickupComponent == nullptr)
			return;

		ACastleElevatorSwitchPickupable PickupableSwitch = Cast<ACastleElevatorSwitchPickupable>(PickupComponent.CurrentPickup);
		if (PickupableSwitch == nullptr)
			return;		

		PickupableSwitch.OnPutDownEvent.AddUFunction(this, n"OnSwitchDropped");
		UPlayerPickupComponent::Get(Player).ForceDrop(true);
	}

	UFUNCTION(NetFunction)
	void NetElevatorStartMoving(AActor Loc_PickupableSwitch)
	{
		bGearPlacedInElevator = true;
		ElevatorDoorTimelike.Play();
		Loc_PickupableSwitch.DestroyActor();
	}

	UFUNCTION()
	void OnSwitchDropped(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		NetElevatorStartMoving(PickupActor);

		//UPickupableComponent::Get(PickupActor).OnActorPutDown.Unbind(this, n"OnSwitchDropped");
		//PickupActor.DestroyActor();
	}

	UFUNCTION()
	void OnElevatorDoorTimelikeUpdate(float CurrentValue)
	{
		ElevatorGateRoot.SetWorldScale3D(FVector(1, 1, CurrentValue));

		if (ElevatorDoorTimelike.IsReversed())
		{
			ElevatorFenceRoot.SetWorldScale3D(FVector(1, 1, CurrentValue));
			GearBaseRoot.SetRelativeLocation(FVector(GearBaseRoot.RelativeLocation.X, GearBaseRoot.RelativeLocation.Y, -200 + CurrentValue * 200));
		}
	}
	UFUNCTION()
	void OnElevatorDoorTimelikeFinished()
	{
		if (!ElevatorDoorTimelike.IsReversed())
		{
			ElevatorMovementTimelike.Play();
			GearMesh.SetHiddenInGame(false);
		}
		else
		{
			GearBaseRoot.SetVisibility(false, true);
		}
	}

	UFUNCTION()
	void OnElevatorMovementTimelikeUpdate(float CurrentValue)
	{
		ElevatorProgress = CurrentValue;

		FVector NewLocation = FMath::Lerp(StartLocation, EndLocation, ElevatorProgress);
		ElevatorRoot.SetRelativeLocation(NewLocation);

		RotateGear(ActorDeltaSeconds);
	}
	UFUNCTION()
	void OnElevatorMovementTimelikeFinished()
	{
		ElevatorDoorTimelike.Reverse();
	}

	void RotateGear(float DeltaTime)
	{
		GearMesh.AddRelativeRotation(FRotator(0, 0, DeltaTime * 100).Quaternion());
	}
}

struct FCastleElevatorSwitchWeight
{
	UPROPERTY()
	ACastleElevatorSwitch ElevatorSwitch;
	UPROPERTY()
	float Weight = 1.f;
}