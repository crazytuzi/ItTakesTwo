import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Hopscotch.WhoopeeCushion;
import Peanuts.Spline.SplineComponent;
import Vino.Bounce.BounceComponent;

event void FPumpGroundPounded(float StretchDuration);

class APumpPaddle : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent BounceRoot;

    UPROPERTY(DefaultComponent, Attach = BounceRoot)
    UStaticMeshComponent CollisionMesh;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UBounceComponent BounceComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPoseableMeshComponent Pump;

    UPROPERTY(DefaultComponent, Attach = Mesh)
    UStaticMeshComponent TubeStartMesh;
    default TubeStartMesh.bAbsoluteScale = true;

    UPROPERTY()
    AWhoopeeCushion WhopeeCushionToTrigger;

	UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

    UPROPERTY(DefaultComponent)
    UHazeAkComponent HazeAkComp;

	UPROPERTY()
	FPumpGroundPounded PumpGroundPounded;

    UPROPERTY()
    UAkAudioEvent PumpPaddleGroundPoundedAudioEvent;

    FVector PumpPressedScale;
    FVector PumpNormalScale;

	FVector CollisionMeshStartLoc = FVector::ZeroVector;
	FVector PumpBoneStartLoc = FVector::ZeroVector;

	float GroundPoundResetTimer = 0.f;
	
	UPROPERTY()
	float InflateDelay = 0.5f;

	bool bShouldTickInflateTimer = false;
	float InflateTimer = 0.f;

	bool bGroundPounded;

    TArray<AActor> PlayersOnPump;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		CollisionMeshStartLoc = CollisionMesh.WorldLocation;
		PumpBoneStartLoc = Pump.GetBoneLocationByName(n"Pump", EBoneSpaces::WorldSpace);

        // PumpNormalScale = Mesh.RelativeScale3D;
        // PumpPressedScale = FVector(Mesh.RelativeScale3D.X, Mesh.RelativeScale3D.Y, Mesh.RelativeScale3D.Z / 4);

		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ButtonGroundPounded");
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector PumpLoc;
		PumpLoc = PumpBoneStartLoc + (CollisionMesh.WorldLocation - CollisionMeshStartLoc);
		Pump.SetBoneLocationByName(n"Pump", PumpLoc, EBoneSpaces::WorldSpace);

		if (GroundPoundResetTimer > 0)
		{
			GroundPoundResetTimer -= DeltaTime;

			if (GroundPoundResetTimer <= 0)
			{
				ResetPump();
			}
		}

		if (bShouldTickInflateTimer)
		{
			InflateTimer -= DeltaTime;

			if (InflateTimer <= 0.f)
			{
				bShouldTickInflateTimer = false;
				NetReadyToLaunchPlayer(WhopeeCushionToTrigger.CushionOverlapCheck());
			}
		}
	}
    
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
    
    }

	UFUNCTION(NotBlueprintCallable)
    void ButtonGroundPounded(AHazePlayerCharacter Player)
    {	 
		if (!Player.OtherPlayer.HasControl())
			return;	

		if (bGroundPounded)
			return;
            
		bGroundPounded = true;
		InflateTimer = InflateDelay;
        bShouldTickInflateTimer = true;
		NetPumpGroundPounded();
    }

	UFUNCTION(NetFunction)
	void NetPumpGroundPounded()
	{
		PumpGroundPounded.Broadcast(InflateDelay);
	}


	UFUNCTION(NetFunction)
	void NetReadyToLaunchPlayer(AHazePlayerCharacter Player)
	{
		GroundPoundResetTimer = .75f;
        HazeAkComp.HazePostEvent(PumpPaddleGroundPoundedAudioEvent);
		WhopeeCushionToTrigger.InflateCushion(Player);
	}

	UFUNCTION()
	void ResetPump()
	{
		GroundPoundResetTimer = 0.f;
		bGroundPounded = false;

    	WhopeeCushionToTrigger.DeflateCushion();
	}
}