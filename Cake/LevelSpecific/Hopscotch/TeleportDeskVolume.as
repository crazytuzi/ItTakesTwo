import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.Helpers.BurstForceStatics;

event void FTeleportTableSignature();

class ATeleportDeskVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionBox;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTrajectoryComponent CodyTrajectory;
	default CodyTrajectory.VisualizeLength = 10000.f;
	default CodyTrajectory.TrajectoryMethod = ETrajectoryMethod::Calculation;
	default CodyTrajectory.LocalTargetPosition = FVector(1500.f, 0.f, 0.f);
	default CodyTrajectory.LocalTargetHeight = FVector(750.f, 0.f, 1000.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UTrajectoryComponent MayTrajectory;
	default MayTrajectory.VisualizeLength = 10000.f;
	default MayTrajectory.TrajectoryMethod = ETrajectoryMethod::Calculation;
	default MayTrajectory.LocalTargetPosition = FVector(1500.f, 0.f, 0.f);
	default MayTrajectory.LocalTargetHeight = FVector(750.f, 0.f, 1000.f);

	UPROPERTY()
	FHazeTimeLike MoveLidTimeline;
	default MoveLidTimeline.Duration = 0.2f;

	UPROPERTY()
	AActor MayTeleportLocationActor;

	UPROPERTY()
	AActor CodyTeleportLocationActor;

	UPROPERTY()
	AStaticMeshActor Lid01;

	UPROPERTY()
	AStaticMeshActor Lid02;

	UPROPERTY()
	FTeleportTableSignature TeleportTableEvent;

	AStaticMeshActor LidToOpen;

	bool BothInVolume;

	FRotator CurrentRotation;
	FRotator TargetRotation;

	FVector MayTeleportLocation;
	FVector CodyTeleportLocation;

	TArray<AHazePlayerCharacter> PlayerArray;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CodyTrajectory.SetRelativeLocation(GetActorTransform().InverseTransformPosition(CodyTeleportLocationActor.GetActorLocation()));
		MayTrajectory.SetRelativeLocation(GetActorTransform().InverseTransformPosition(MayTeleportLocationActor.GetActorLocation()));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionBox.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		CollisionBox.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
		
		MoveLidTimeline.BindUpdate(this, n"MoveLidTimelineUpdate");

		MayTeleportLocation = MayTeleportLocationActor.ActorLocation;
		CodyTeleportLocation = CodyTeleportLocationActor.ActorLocation;
	}

	UFUNCTION()
	void MoveLidTimelineUpdate(float CurrentValue)
	{
		LidToOpen.StaticMeshComponent.SetRelativeRotation(QuatLerp(CurrentRotation, TargetRotation, CurrentValue));
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			PlayerArray.AddUnique(Cast<AHazePlayerCharacter>(OtherActor));
			AreBothPlayerInVolume();
		}
    }

	UFUNCTION()
    void TriggeredOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr && !BothInVolume)
		{
			PlayerArray.Remove(Cast<AHazePlayerCharacter>(OtherActor));
		}
    }

	UFUNCTION()
	void AreBothPlayerInVolume()
	{
		if (PlayerArray.Num() == 2 && !BothInVolume)
		{
			BothInVolume = true;
			LidToOpen = Lid01;
			CurrentRotation = Lid01.StaticMeshComponent.RelativeRotation;
			TargetRotation = FRotator (Lid01.StaticMeshComponent.RelativeRotation + FRotator(40.f, 0.f, 0.f));

			for (AHazePlayerCharacter Player : PlayerArray)
			{
				Player.BlockCapabilities(n"Movement", this);
			}

			TeleportTableEvent.Broadcast();

			System::SetTimer(this, n"CloseFirstLid", 1.f, false);			
		}
	}

	UFUNCTION()
	void CloseFirstLid()
	{
		MoveLidTimeline.PlayFromStart();
		
		System::SetTimer(this, n"MovePlayers", 2.f, false);	
	}

	UFUNCTION()
	void MovePlayers()
	{
		for (AHazePlayerCharacter Player : PlayerArray)
		{
			FVector TeleportLocation = Player == Game::GetCody() ? CodyTeleportLocation : MayTeleportLocation;

			Player.SetActorLocation(TeleportLocation);
		}

		System::SetTimer(this, n"OpenSecondLid", 2.f, false);
	}

	UFUNCTION()
	void OpenSecondLid()
	{
		BothInVolume = true;
		LidToOpen = Lid02;
		CurrentRotation = Lid02.StaticMeshComponent.RelativeRotation;
		TargetRotation = FRotator (Lid02.StaticMeshComponent.RelativeRotation + FRotator(-40.f, 0.f, 0.f));
		MoveLidTimeline.PlayFromStart();
		System::SetTimer(this, n"LaunchPlayers", 0.2f, false);
	}

	UFUNCTION()
	void LaunchPlayers()
	{
		Print("Launch", 2.0f);
		for(AHazePlayerCharacter Player : PlayerArray)
		{
			Player.UnblockCapabilities(n"Movement", this);
			UTrajectoryComponent TrajectoryComp = Player == Game::GetCody() ? CodyTrajectory : MayTrajectory;
			TrajectoryComp.Gravity = Player.GetActorGravity().Size();
			FVector Velo = TrajectoryComp.CalculatedVelocity;
			AddBurstForce(Player, Velo, Player.GetActorRotation());
		}
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}