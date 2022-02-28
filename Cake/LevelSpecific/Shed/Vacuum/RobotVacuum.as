import Peanuts.Spline.SplineComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FOnPlayerLandedOnRobotVacuum(AHazePlayerCharacter Player);

event void LandOnVacuum();
event void LeaveVacuum();

UCLASS(Abstract)
class ARobotVacuum : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase RobotMesh;

	UPROPERTY(DefaultComponent, Attach = RobotMesh)
	UHazeAkComponent HazeAkComp;

    UPROPERTY(DefaultComponent)
    USplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartHoveringAudioEvent;

	UPROPERTY(Category = "Audio Events")
	bool bIsAMovingVacuum = false;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HoverMh;

    UPROPERTY()
    FRotator IdleRotationRate = FRotator(0.f, 50.f, 0.f);
    UPROPERTY()
    FRotator MountedRotationRate = FRotator(0.f, 200.f, 0.f);
    FRotator CurrentRotationRate;

	UPROPERTY(NotEditable)
	float AnimPlayRate = 1.f;

	UPROPERTY()
	float StartDelay = 0.f;

    UPROPERTY()
    float SpeedAlongSpline = 100.f;
    float DistanceAlongSpline = 0.f;

    TArray<AHazePlayerCharacter> PlayersOnRobot;

    UPROPERTY()
    bool bAlwaysMoveAlongSpline = false;

    UPROPERTY()
    FOnPlayerLandedOnRobotVacuum OnPlayerLanded;

    UPROPERTY()
    float VerticalOffset;

    UPROPERTY(NotVisible)
    bool bEnabled = true;

	UPROPERTY()
	LandOnVacuum AudioLandOnVacuum;

	UPROPERTY()
	LeaveVacuum AudioLeaveVacuum;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Spline.DetachFromParent(true, false);

        if (!bAlwaysMoveAlongSpline)
		{
			if (StartDelay == 0)
            	StartHovering();
			else
				System::SetTimer(this, n"StartHovering", StartDelay, false);
		}

		CurrentRotationRate = IdleRotationRate;

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnRobot");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeaveRobot");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        RobotMesh.AddWorldRotation(CurrentRotationRate * Delta);

        if (PlayersOnRobot.Num() != 0 || bAlwaysMoveAlongSpline)
        {
            DistanceAlongSpline = DistanceAlongSpline + SpeedAlongSpline * Delta;

            FVector DesiredLocation = Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) + FVector(0.f, 0.f, VerticalOffset);
            RobotMesh.SetWorldLocation(FMath::VInterpTo(RobotMesh.GetWorldLocation(), DesiredLocation, Delta, 5.f));

            if (DistanceAlongSpline >= Spline.SplineLength)
            {
                if (Spline.IsClosedLoop())
                    DistanceAlongSpline = 0.f;
                else
                    SpeedAlongSpline *= -1;
            }

            if (DistanceAlongSpline < 0)
                SpeedAlongSpline *= -1;
        }
    }

    UFUNCTION()
    void DisableRobotVacuum()
    {
        bEnabled = false;
    }
	
	UFUNCTION(NotBlueprintCallable)
	void LandOnRobot(AHazePlayerCharacter Player, FHitResult Hit)
	{
		AddPlayerToRobot(Player);
		AudioLandOnVacuum.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void LeaveRobot(AHazePlayerCharacter Player)
	{
		RemovePlayerFromRobot(Player);
		AudioLeaveVacuum.Broadcast();
	}

    UFUNCTION(NetFunction)
    void AddPlayerToRobot(AHazePlayerCharacter Player)
    {
        PlayersOnRobot.Add(Player);
        CurrentRotationRate = MountedRotationRate;
        OnPlayerLanded.Broadcast(Player);
		
		AnimPlayRate = 2.f;
		RobotMesh.SetSlotAnimationPlayRate(HoverMh, 2.f);
		HazeAkComp.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_FlyingVacuum_SwaySpeed", 1.5f);
    }

    UFUNCTION(NetFunction)
    void RemovePlayerFromRobot(AHazePlayerCharacter Player)
    {
        PlayersOnRobot.Remove(Player);

        if (PlayersOnRobot.Num() == 0)
        {
            CurrentRotationRate = IdleRotationRate;
			AnimPlayRate = 1.f;
			RobotMesh.SetSlotAnimationPlayRate(HoverMh, 1.f);
			HazeAkComp.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_FlyingVacuum_SwaySpeed", 1.f);
        }
    }

    UFUNCTION()
    void StartHovering()
    {
		PlaySlotAnimation(Animation = HoverMh, bLoop = true);
		if (bIsAMovingVacuum && StartHoveringAudioEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(StartHoveringAudioEvent);
		}
		
    }
}