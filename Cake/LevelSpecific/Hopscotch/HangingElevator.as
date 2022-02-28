import Vino.Interactions.InteractionComponent;

event void FHangingElevatorSignature();

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHangingElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike LowerElevatorTimeline;
	default LowerElevatorTimeline.Duration = 3.f;

	UPROPERTY()
	TSubclassOf<UHazeCapability> HangingElevatorCapability;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionCompLeft;
	default InteractionCompLeft.RelativeLocation = FVector(0.f, -335.f, 10.f);
	default InteractionCompLeft.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default InteractionCompLeft.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 2.f);
	default InteractionCompLeft.ActionShapeTransform.Location = FVector(0.f, 0.f, -190.f);
	default InteractionCompLeft.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionCompRight;
	default InteractionCompRight.RelativeLocation = FVector(0.f, 335.f, 10.f);
	default InteractionCompRight.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default InteractionCompRight.ActionShapeTransform.Location = FVector(0.f, 0.f, -190.f);
	default InteractionCompRight.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 2.f);
	default InteractionCompRight.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY()
	AActor ActorToLift;

	UPROPERTY()
	FHangingElevatorSignature ElevatorStartedEvent;

	TArray<AHazePlayerCharacter> PlayersUsingElevator;

	FVector StartingLocation;
	FVector TargetLocation;

	FVector LiftActorStartingLocation;
	FVector LiftActorTargetLocation;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LowerElevatorTimeline.BindUpdate(this, n"LowerElevatorTimelineUpdate");
		
		InteractionCompLeft.OnActivated.AddUFunction(this, n"ElevatorActivated");
		InteractionCompRight.OnActivated.AddUFunction(this, n"ElevatorActivated");

		StartingLocation = Root.RelativeLocation;
		TargetLocation = FVector(Root.RelativeLocation + FVector(0.f, 0.f, -3000.f));

		LiftActorStartingLocation = ActorToLift.GetActorLocation();
		LiftActorTargetLocation = FVector(ActorToLift.GetActorLocation() + FVector(0.f, 0.f, 3000.f));
	}

	UFUNCTION()
	void LowerElevatorTimelineUpdate(float CurrentValue)
	{
		Root.SetRelativeLocation(FMath::VLerp(StartingLocation, TargetLocation, FVector(CurrentValue, CurrentValue, CurrentValue)));
		ActorToLift.SetActorLocation((FMath::VLerp(LiftActorStartingLocation, LiftActorTargetLocation, FVector(CurrentValue, CurrentValue, CurrentValue))));
	}

	UFUNCTION()
	void ElevatorActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		if (PlayersUsingElevator.AddUnique(Player))
		{

			Player.AddCapability(HangingElevatorCapability);
			Player.SetCapabilityAttributeObject(n"InteractionComponent", Comp);
			Player.SetCapabilityAttributeObject(n"HangingElevator", this);
		
			Player.AttachToComponent(AttachComponent, n"", EAttachmentRule::KeepWorld);
			BothPlayersUsingElevator();
			
			Comp.Disable(n"InUse");
		}		
	}

	UFUNCTION()
	void BothPlayersUsingElevator()
	{
		if (PlayersUsingElevator.Num() == 2)
		{
			LowerElevatorTimeline.PlayFromStart();
			ElevatorStartedEvent.Broadcast();
			System::SetTimer(this, n"ElevatorHasBeenUsed", 3.f, false);
		}
	}

	UFUNCTION()
	void DetachPlayerFromActor(AHazePlayerCharacter Player, UInteractionComponent InteractionComp)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		InteractionComp.Enable(n"InUse");
		PlayersUsingElevator.Remove(Player);
	}

	UFUNCTION()
	void ElevatorHasBeenUsed()
	{
		InteractionCompLeft.Disable(n"");
		InteractionCompRight.Disable(n"");

		for (AHazePlayerCharacter Player : PlayersUsingElevator)
		{
			Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			Player.SetCapabilityAttributeObject(n"HangingElevator", nullptr);
		}
	}
}