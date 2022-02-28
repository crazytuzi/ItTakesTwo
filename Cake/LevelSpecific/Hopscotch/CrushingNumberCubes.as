import Cake.LevelSpecific.Hopscotch.NumberCube;
import Vino.PlayerHealth.PlayerHealthStatics;

class ACrushingNumberCubes : AHazeActor 
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent CubeMesh;

	UPROPERTY(DefaultComponent, Attach = CubeMesh)
	UStaticMeshComponent LeftSideStopper;

	UPROPERTY(DefaultComponent, Attach = CubeMesh)
	UStaticMeshComponent RightSideStopper;

	UPROPERTY(DefaultComponent, Attach = CubeMesh)
	USceneComponent AttachComponent;

    UPROPERTY(DefaultComponent, Attach = CubeMesh)
    UBoxComponent RagdollCollision;
    default RagdollCollision.BoxExtent = FVector(52.f, 52.f, 52.f);

	UPROPERTY(DefaultComponent, Attach = CubeMesh)
	UBoxComponent CrushCollision;
	default CrushCollision.BoxExtent = FVector(45.f, 45.f, 45.f);

    UPROPERTY()
    FHazeTimeLike CrushTimeline;
    default CrushTimeline.Duration = 0.2f;

    UPROPERTY()
    float CrushDuration;
    default CrushDuration = 0.5f;

    UPROPERTY()
    float LiftDuration;
    default LiftDuration = 3.f;

    UPROPERTY()
    EHopScotchNumber HopscotchNumber;

	UPROPERTY()
	bool bKillPlayerOnContact;
    
    UPROPERTY()
    TArray<UMaterialInstance> MaterialArray;

    UPROPERTY(meta = (MakeEditWidget))
    FVector TargetLiftLocation;

    UPROPERTY()
    FVector CubeInitialLocation;

    UPROPERTY()
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	TArray<AActor> ActorsToAttach;

    UPROPERTY()
    bool bReversed;

    UPROPERTY()
    bool bShowTargetLiftLocation;

	UPROPERTY()
	bool bLeftSideStopper = false;

	UPROPERTY()
	bool bRightSideStopper = false;

    bool bActivated;
    int ActivationCounter;

    UFUNCTION(BlueprintEvent)
    void BP_CubeLift()
    {}

    UFUNCTION(BlueprintEvent)
    void BP_CubeDown()
    {}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (bShowTargetLiftLocation)
            CubeMesh.SetRelativeLocation(TargetLiftLocation);

        else
            CubeMesh.SetRelativeLocation(FVector::ZeroVector);

        CubeMesh.SetMaterial(1, MaterialArray[HopscotchNumber]);

		if (bLeftSideStopper)
		{
			LeftSideStopper.SetVisibility(true);
			LeftSideStopper.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		} else
		{
			LeftSideStopper.SetVisibility(false);
			LeftSideStopper.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		if (bRightSideStopper)
		{
			RightSideStopper.SetVisibility(true);
			RightSideStopper.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		} else
		{
			RightSideStopper.SetVisibility(false);
			RightSideStopper.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CrushTimeline.BindUpdate(this, n"CrushTimelineUpdate");
        CrushTimeline.BindFinished(this, n"CrushTimelineFinished");
        
        FTransform CubeTransform = CubeMesh.GetRelativeTransform();
        CubeInitialLocation = CubeTransform.Location;
       
	    RagdollCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnRagdollCollisionOverlap");
		CrushCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnCrushCollisionOverlap");

        if (bReversed)
            CubeMesh.SetRelativeLocation(TargetLiftLocation);

		if (ActorsToAttach.Num() > 0)
		{
			for (AActor Actor : ActorsToAttach)
			{
				Actor.AttachToComponent(AttachComponent, n"", EAttachmentRule::KeepWorld);
			}
		}
    }

    UFUNCTION()
    void OnRagdollCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        if (bKillPlayerOnContact)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor); 
			if (Player != nullptr && !bActivated)
				KillPlayer(Player, DeathEffect);
		}
    }

	UFUNCTION()
	void OnCrushCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{		
		if (!bActivated)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor); 
			if (Player != nullptr && !bActivated)
				KillPlayer(Player, DeathEffect);
		}
	}
    
	UFUNCTION()
    void CrushTimelineUpdate(float CurrentValue)
    {
        CubeMesh.SetRelativeLocation(FMath::VLerp(CubeInitialLocation, TargetLiftLocation, FVector(CurrentValue, CurrentValue, CurrentValue)));
    }

    UFUNCTION()
    void CrushTimelineFinished(float CurrentValue)
    {
        CubeMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
    }

	UFUNCTION(NetFunction)
	void NetLiftCube()
	{
		LiftCube();
	}
	
	UFUNCTION()
    void LiftCube()
    {
        if (!bActivated && ActivationCounter == 0)
        {
            bActivated = true;
            CrushTimeline.SetNewTime(bReversed ? CrushTimeline.Duration : 0.f);
            bReversed ? CrushTimeline.Reverse() : CrushTimeline.Play();
            BP_CubeLift();
        } else
        {
            ActivationCounter++;
        }
    }

	UFUNCTION(NetFunction)
	void NetCrushCube()
	{
		CrushCube();
	}
   
    UFUNCTION()
    void CrushCube()
    {
        if (bActivated && ActivationCounter == 0)
        {
            bActivated = false;
            CubeMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
            CrushTimeline.SetNewTime(bReversed ? 0.f : CrushTimeline.Duration);
            bReversed ? CrushTimeline.Play() : CrushTimeline.Reverse();
            BP_CubeDown();
        } else
        {
            ActivationCounter--;
        }
    }

	UFUNCTION()
	void MoveCubeWithLever(float LeverValue)
	{
		CubeMesh.SetRelativeLocation(FMath::VLerp(CubeInitialLocation, TargetLiftLocation, FVector(LeverValue, LeverValue, LeverValue)));
	}
}