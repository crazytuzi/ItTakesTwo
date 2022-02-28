import Peanuts.Spline.SplineComponent;

class ASpawnableTunnel : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent TunnelMesh;

    // UGLY TEMPORARY THINGY!!
    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild1;
    default TunnelMeshChild1.SetRelativeLocation(FVector(0.f, 0.f, -200.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild2;
    default TunnelMeshChild2.SetRelativeLocation(FVector(0.f, 0.f, -400.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild3;
    default TunnelMeshChild3.SetRelativeLocation(FVector(0.f, 0.f, -600.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild4;
    default TunnelMeshChild4.SetRelativeLocation(FVector(0.f, 0.f, -800.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild5;
    default TunnelMeshChild5.SetRelativeLocation(FVector(0.f, 0.f, -1000.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild6;
    default TunnelMeshChild6.SetRelativeLocation(FVector(0.f, 0.f, -1200.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild7;
    default TunnelMeshChild7.SetRelativeLocation(FVector(0.f, 0.f, -1400.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild8;
    default TunnelMeshChild8.SetRelativeLocation(FVector(0.f, 0.f, -1600.f));

    UPROPERTY(DefaultComponent, Attach = TunnelMesh)
    UStaticMeshComponent TunnelMeshChild9;
    default TunnelMeshChild9.SetRelativeLocation(FVector(0.f, 0.f, -200.f));

    UPROPERTY(DefaultComponent, Attach = Root)
    UHazeSplineComponent SplineComponent;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent EnterTunnelCollision;

    UPROPERTY()
    bool bStartDeactivated;

    UPROPERTY()
    FHazeTimeLike ScaleTunnelTimeline;
    default ScaleTunnelTimeline.Duration = 3.f;

    UPROPERTY()
    TArray<UStaticMeshComponent> MeshArray;
    
    FVector StartingScale;
    FVector TargetScale;

	UPROPERTY()
	TSubclassOf<UHazeCapability> MoveThroughTunnelCapability;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ScaleTunnelTimeline.BindUpdate(this, n"ScaleTunnelUpdate");
        ScaleTunnelTimeline.BindFinished(this, n"ScaleTunnelFinished");

        TargetScale = TunnelMesh.GetWorldScale();
        TunnelMesh.SetWorldScale3D(FVector(0.f, 0.f, TargetScale.Z));
        StartingScale = TunnelMesh.GetWorldScale();

        EnterTunnelCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnEnterTunnel");

        if (bStartDeactivated)
            SetSpawnTunnelEnterCollisionEnabled(false);
    }

    UFUNCTION()
    void OnEnterTunnel(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player != nullptr && Player.HasControl())
        {
			Print("ENTER?", 2.f);
			Player.AddCapability(MoveThroughTunnelCapability);
            Player.SetCapabilityActionState(n"InsideTunnel", EHazeActionState::Active);
            Player.SetCapabilityAttributeObject(n"TunnelSpline", SplineComponent);

			if (!Player.OtherPlayer.HasControl())
			{
				 Player.OtherPlayer.SetCapabilityActionState(n"InsideTunnel", EHazeActionState::Active);
           		 Player.OtherPlayer.SetCapabilityAttributeObject(n"TunnelSpline", SplineComponent);
			}
        } 
    }

    UFUNCTION()
    void ScaleTunnelUpdate(float CurrentValue)
    {
        TunnelMesh.SetWorldScale3D(FMath::VLerp(StartingScale, TargetScale, FVector(CurrentValue, CurrentValue, CurrentValue)));
    }

	UFUNCTION()
	void ScaleTunnel(float LerpValue)
	{
		TunnelMesh.SetWorldScale3D(FMath::VLerp(StartingScale, TargetScale, FVector(LerpValue, LerpValue, LerpValue)));
	}

    UFUNCTION()
    void ScaleTunnelFinished(float CurrentValue)
    { 
        if (CurrentValue >= 1.f)
        {
            if (EnterTunnelCollision.GetCollisionEnabled() == ECollisionEnabled::NoCollision)
            {
                SetSpawnTunnelEnterCollisionEnabled(true);
            }
        }
    }

    UFUNCTION()
    void SpawnTunnel()
    {
        ScaleTunnelTimeline.PlayFromStart();
    }

	UFUNCTION()
	void SetSpawnTunnelEnterCollisionEnabled(bool bEnabled)
	{
		ECollisionEnabled Collision = bEnabled ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision; 
		EnterTunnelCollision.SetCollisionEnabled(Collision);
	}

    UFUNCTION()
    void DespawnTunnel()
    {
        ScaleTunnelTimeline.ReverseFromEnd();
        //EnterTunnelCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }
}