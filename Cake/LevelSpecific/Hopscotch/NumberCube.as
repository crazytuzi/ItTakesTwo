import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Tilt.TiltComponent;
import Vino.Bounce.BounceComponent;
enum EHopScotchNumber
{  
    Hopscotch00,
    Hopscotch01,
    Hopscotch02,
    Hopscotch03,
    Hopscotch04,
    Hopscotch05,
    Hopscotch06,
    Hopscotch07,
    Hopscotch08,
    Hopscotch09
};

event void FlippingCubeRotate();

class ANumberCube : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTiltComponent TiltComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ImpulseRoot;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	USceneComponent BounceMeshRoot;

	UPROPERTY(DefaultComponent, Attach = BounceMeshRoot)
	UBounceComponent BounceComp;
	default BounceComp.bMoveComponentInWorldSpace = true;

    UPROPERTY(DefaultComponent, Attach = BounceMeshRoot)
    UStaticMeshComponent Cube;

    UPROPERTY(DefaultComponent)
    UHazeAkComponent HazeAkComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformActivateAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformDeactivateAudioEvent;

	UPROPERTY()
	UStaticMesh NeutralWoodCubeMesh;

	UPROPERTY()
	UStaticMesh StickerWoodCubeMesh;

	TArray<AHazePlayerCharacter> PlayerArray;
	TArray<AHazePlayerCharacter> BlockedPlayers;

    UPROPERTY()
    FHazeTimeLike ShowCubeTimeline;
    default ShowCubeTimeline.Duration = 1.0f;
	default ShowCubeTimeline.bSyncOverNetwork = true;
	default ShowCubeTimeline.SyncTag = n"NumberCubeTimeline";

    // The Position of the cube when hidden
    UPROPERTY(ExposeOnSpawn, meta = (MakeEditWidget), meta = (EditCondition = "bShouldBeHidden || bVisibleWhileDeactivated"))
    FVector CubePosition;

	FVector SavedCubePosition;
	FVector SavedWorldPosition;

    UPROPERTY(ExposeOnSpawn, Category = "Construction")
    EHopScotchNumber HopScotchNumber;

    UPROPERTY()
    TArray<UMaterialInterface> MaterialArray;

	UPROPERTY()
	bool debugmode;

    UPROPERTY(ExposeOnSpawn)
    bool bAttachedToMovingActor;   

    UPROPERTY()
    float MaxDegreesToRotate;
	default MaxDegreesToRotate = 15.0f;
    
    UPROPERTY()
    AHazePlayerCharacter PlayerRef;
      
    UPROPERTY()
    bool bPlayerOnPlatform;

    UPROPERTY()
    AActor OverlappingPlayer;

	

	/* -----------------------
		Rotating Number Cubes
		-----------------------*/

	UPROPERTY()
	FHazeTimeLike RotateCubeTimeline;
	default RotateCubeTimeline.Duration = 1.f;
	default RotateCubeTimeline.bSyncOverNetwork = false;
	default RotateCubeTimeline.SyncTag = n"RotatingNumberCubes";

	FRotator StartingRotation = FRotator::ZeroRotator;
	FRotator TargetRotation = StartingRotation + FRotator(0.f, 0.f, RotationToAdd);
	float RotationToAdd = 180;

	/* ------------------------*/

    UPROPERTY()
    float ShowCubeTimelineDuration;
	default ShowCubeTimelineDuration = 0.7f;

    UPROPERTY(Category = "Construction", meta = (EditCondition = "bShouldBeHidden || bVisibleWhileDeactivated"))
    bool bShowHiddenState;
    
    UPROPERTY(ExposeOnSpawn)
    bool bShouldBeHidden;

	UPROPERTY(meta = (EditCondition = "!bShouldBeHidden"))
	bool bVisibleWhileDeactivated;

    UPROPERTY()
    bool bShouldBeEmissive;

	UPROPERTY()
	bool bShouldCrushPlayers = false;

    UPROPERTY()
    bool bShouldBounce;
	default bShouldBounce = true;

    UPROPERTY()
    bool bShouldTilt;
	default bShouldTilt = true;

    UPROPERTY()
    bool bShouldBeGlowCube;

    UPROPERTY()
    UMaterialInstance GlowCubeMat;

    UPROPERTY()
    AActor ActorToAttach;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

    UPROPERTY(Category = "Audio")
    float MaxElevationTrackRange = 1000.f;

	UPROPERTY()
	bool bRotatingCubes = false;

	UPROPERTY()
	bool bStartWithBounceAndTiltDisabled = false;

	bool bCubeWasRotated = true;

	bool bCubeIsMovingFromHiddenState = false;

	float CubeIsMovingTimer = 0.f;
    
    bool bPlatformActive;
    float InterpSpeed = 3.0f;
    int ActivationCounter;

    UPROPERTY()
    FlippingCubeRotate AudioFlippingCubeRotate;

	FHazeConstrainedPhysicsValue PhysValue;
	FVector ImpulseDirection;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	
    // Binding Collision functions and Timlike functions
    // on BeginPlay
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		PhysValue.LowerBound = -750.f;
		PhysValue.UpperBound = 1500.f;
		PhysValue.LowerBounciness = 1.f;
		PhysValue.UpperBounciness = 0.65f;
		PhysValue.Friction = 3.f;

		if (bRotatingCubes)
		{
			FActorImpactedByPlayerDelegate ImpactDelegate;
			ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
			BindOnDownImpactedByPlayer(this, ImpactDelegate);

			FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
			NoImpactDelegate.BindUFunction(this, n"PlayerLeftActor");
			BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
		}

        ShowCubeTimeline.BindUpdate(this, n"ShowCubeTimelineUpdate");
        ShowCubeTimeline.BindFinished(this, n"ShowCubeTimelineFinished");

		RotateCubeTimeline.BindUpdate(this, n"RotateCubeTimelineUpdate");
		RotateCubeTimeline.BindFinished(this, n"RotateCubeTimelineFinished");

		if (!bShouldBounce)
			BounceComp.SetBounceComponentEnabled(false);

		if (!bShouldTilt)
			TiltComp.SetTiltComponentEnabled(false);

        if (bShouldBeHidden)
        {
            Cube.SetScalarParameterValueOnMaterials(n"Opacity", 0.0f);
            MeshRoot.SetRelativeLocation(CubePosition);
        } else if (bVisibleWhileDeactivated)
		{
			MeshRoot.SetRelativeLocation(CubePosition);
			Cube.SetScalarParameterValueOnMaterials(n"Opacity", 2.0f);
		} else 
        {
            Cube.SetScalarParameterValueOnMaterials(n"Opacity", 2.0f);
        }

        if (ActorToAttach != nullptr)
            ActorToAttach.AttachToComponent(BounceMeshRoot, n"", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

        ImpulseDirection = ActorLocation - MeshRoot.WorldLocation;
		ImpulseDirection.Normalize();

		if (bStartWithBounceAndTiltDisabled)
		{
			BounceComp.SetBounceComponentEnabled(false);
			TiltComp.SetTiltComponentEnabled(false);
		}

		HazeAkComponent.SetTrackElevation(true);
        HazeAkComponent.SetMaxElevationTrackRange(MaxElevationTrackRange);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {    
		if (bCubeIsMovingFromHiddenState)
		{
			CubeIsMovingTimer -= DeltaTime;
			
			if (CubeIsMovingTimer <= 0.f)
				bCubeIsMovingFromHiddenState = false;
		}

		PhysValue.SpringTowards(0.f, 100.f);
		PhysValue.Update(DeltaTime);
		ImpulseRoot.SetRelativeLocation(ImpulseDirection * -PhysValue.Value);

		// Stop ticking if the cube is not moving anymore
		if (!bCubeIsMovingFromHiddenState && PhysValue.CanSleep(SettledTargetValue = 0.f))
			SetActorTickEnabled(false);
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (HopScotchNumber == EHopScotchNumber::Hopscotch00)
        {
            Cube.SetVectorParameterValueOnMaterials(n"Color1", GetRandomColor());
            Cube.SetVectorParameterValueOnMaterials(n"Color2", GetRandomColor());
        }
        
        if (bShowHiddenState)
            MeshRoot.SetRelativeLocation(CubePosition);
         else
            MeshRoot.SetRelativeLocation(FVector(0,0,0));

        if (bShouldBeGlowCube)
            Cube.SetMaterial(1, GlowCubeMat);
        else  
			Cube.SetMaterial(1, MaterialArray[HopScotchNumber]);

		if (HopScotchNumber == EHopScotchNumber::Hopscotch00)
			Cube.SetStaticMesh(NeutralWoodCubeMesh);    
		else
			Cube.SetStaticMesh(StickerWoodCubeMesh);    

		if (bShouldBeHidden || bVisibleWhileDeactivated)
			BounceComp.bMoveComponentInWorldSpace = false;
		
    }

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		// if (Player.HasControl())
		// 	PlayerArray.AddUnique(Player);
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		// if (Player.HasControl())
		// 	PlayerArray.Remove(Player);
	}

	UFUNCTION(CallInEditor)
	void SaveCurrentHiddenPosition()
	{
		SavedCubePosition = MeshRoot.WorldLocation;
	}

	UFUNCTION(CallInEditor)
	void ApplySavedHiddenPosition()
	{
		if (SavedCubePosition.Size() != 0.f)
			CubePosition = GetActorTransform().InverseTransformPosition(SavedCubePosition);
	}

	UFUNCTION(CallInEditor)
	void SaveCurrentWorldPosition()
	{
		SavedWorldPosition = MeshRoot.WorldLocation;
	}

	UFUNCTION(CallInEditor)
	void ApplySavedWorldPosition()
	{
		if (SavedWorldPosition.Size() != 0.f)
			SetActorLocation(SavedWorldPosition);
	}

	UFUNCTION(CallInEditor)
	void SetCurrentPositionAsVisiblePositionAndResetCubePosition()
	{
		FVector CurrentLoc = MeshRoot.WorldLocation;
		CubePosition = FVector::ZeroVector;
		SetActorLocation(CurrentLoc);
		bShowHiddenState = false;
	}

    FVector GetRandomColor()
    {
        FLinearColor Color = FLinearColor::MakeRandomColor();
        FVector RandomColorVector = FVector (Color.R, Color.G, Color.B);

        return RandomColorVector;
    }

	UFUNCTION(NetFunction)
	void NetActivatePlatform()
	{
		ActivatePlatform(false);
	}	
	
	UFUNCTION()
    void ActivatePlatform(bool bActivatedFromProgressPoint)
    {
        BounceComp.SetBounceComponentEnabled(true);
		TiltComp.SetTiltComponentEnabled(true);

		if (bActivatedFromProgressPoint)
        {
            bPlatformActive = true;

            ShowCubeTimeline.SetPlayRate(1 / ShowCubeTimelineDuration);
            Cube.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            ShowCubeTimeline.PlayFromStart();
            ActivationCounter = 0;
        } else
        {
            if (!bPlatformActive && ActivationCounter == 0)
            {
                bPlatformActive = true;

                ShowCubeTimeline.SetPlayRate(1 / ShowCubeTimelineDuration);
                Cube.SetCollisionEnabled(ECollisionEnabled::NoCollision);
                ShowCubeTimeline.Play();
				HazeAkComponent.HazePostEvent(PlatformActivateAudioEvent);
            } else 
            {
                ActivationCounter++;
            }
        }
    }

	UFUNCTION(NetFunction)
	void NetDeactivatePlatform()
	{
		DeactivatePlatform(false);
		CubeIsMovingTimer = ShowCubeTimelineDuration;
		bCubeIsMovingFromHiddenState = true;
		SetActorTickEnabled(true);
	}
    
    UFUNCTION()
    void DeactivatePlatform(bool bDeactivatedFromProgressPoint)
    {
		BounceComp.SetBounceComponentEnabled(false);
		TiltComp.SetTiltComponentEnabled(false);

		if (bDeactivatedFromProgressPoint)
        {
            bPlatformActive = false;
                
            ShowCubeTimeline.SetPlayRate(1 / ShowCubeTimelineDuration);
            Cube.SetCollisionEnabled(ECollisionEnabled::NoCollision);
            ShowCubeTimeline.ReverseFromEnd();
            ActivationCounter = 0;
        } else
        {
            if (bPlatformActive && ActivationCounter == 0)
            {
                bPlatformActive = false;                
                
				ShowCubeTimeline.SetPlayRate(1 / ShowCubeTimelineDuration);
                Cube.SetCollisionEnabled(ECollisionEnabled::NoCollision);
                ShowCubeTimeline.Reverse();
				HazeAkComponent.HazePostEvent(PlatformDeactivateAudioEvent);
            } else
                ActivationCounter--;
        }
    }

    UFUNCTION()
    void ShowCubeTimelineUpdate(float CurrentValue)
    {
    	MeshRoot.SetRelativeLocation(FMath::Lerp(CubePosition, FVector::ZeroVector, CurrentValue));
	   
		if(!bVisibleWhileDeactivated)
			Cube.SetScalarParameterValueOnMaterials(n"Opacity", FMath::Lerp(0.0f, 2.0f, CurrentValue));
    }

    UFUNCTION()
    void ShowCubeTimelineFinished(float CurrentValue)
    {  
		Cube.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		
		if (CurrentValue > 0.9f)
		{
			PhysValue.AddImpulse(-2000.f);
			SetActorTickEnabled(true);
		}
    }

    UFUNCTION()
    void BounceTimelineUpdate(float CurrentValue)
    {
        MeshRoot.SetRelativeLocation(FVector(FMath::VLerp(FVector(0,0,0), FVector(0,0,-20.0f), FVector(0,0,CurrentValue))));
    }

	UFUNCTION(BlueprintEvent)
	void CubeIsRotating(bool bRotatingForward)
	{
	
	}

	void CubeWasRotated(bool bRotatingForward)
	{
		if (bCubeWasRotated && bRotatingForward)
		{
			bCubeWasRotated = false;
			CubeIsRotating(bRotatingForward);
            AudioFlippingCubeRotate.Broadcast();
		}

		if (!bCubeWasRotated && !bRotatingForward)
		{
			bCubeWasRotated = true;
			CubeIsRotating(bRotatingForward);
            AudioFlippingCubeRotate.Broadcast();
		}
	}

    UFUNCTION()
    void SetCubesEmissive()
    {
        if (bShouldBeEmissive)
            Cube.SetScalarParameterValueOnMaterialIndex(0, n"Emissive", 0.5f);
    }

    UFUNCTION()
    void SetNumberCubesProperties(FVector NumberCubePosition, EHopScotchNumber HopscotchNumberToSpawn, bool bIsAttachedToMovingActor, 
        bool bCubeShouldBeHidden, bool bShouldCubeBeEmissive, bool bShouldCubeTilt, bool bShouldCubeBounce, FVector Scale, bool bShouldGlow, bool bNewVisibleWhileDeactivated)
    {
        CubePosition = NumberCubePosition;
        HopScotchNumber = HopscotchNumberToSpawn;
        bAttachedToMovingActor = bIsAttachedToMovingActor;
        bShouldBeHidden = bCubeShouldBeHidden;
        bShouldBeEmissive = bShouldCubeBeEmissive;
        bShouldTilt = bShouldCubeTilt;
        bShouldBounce = bShouldCubeBounce;
		bVisibleWhileDeactivated = bNewVisibleWhileDeactivated;
    
        if (bShouldGlow)
            Cube.SetMaterial(0, GlowCubeMat);
        else
            Cube.SetMaterial(0, MaterialArray[HopScotchNumber]);
        
        SetCubesEmissive();

        SetActorScale3D(Scale);

        if (bShouldBeHidden)
        {
            Cube.SetScalarParameterValueOnMaterials(n"Opacity", 0.0f);
            MeshRoot.SetRelativeLocation(CubePosition);
        }

		if (bVisibleWhileDeactivated)
		{
			MeshRoot.SetRelativeLocation(CubePosition);
		}
    }

	UFUNCTION()
	void StartRotatingCube(float RotationDuration)
	{
		// for(auto Player : PlayerArray)
		// {
		// 	Player.AttachToComponent(MeshRoot, n"", EAttachmentRule::KeepWorld);
		// 	Player.BlockCapabilities(CapabilityTags::Movement, this);
		// 	BlockedPlayers.AddUnique(Player);
		// }

		StartingRotation = MeshRoot.RelativeRotation;
		TargetRotation = MeshRoot.RelativeRotation + FRotator(0.f, 0.f, RotationToAdd);
		RotateCubeTimeline.SetPlayRate(1 / RotationDuration);
		RotateCubeTimeline.PlayFromStart();
		AudioFlippingCubeRotate.Broadcast();		
	}


	UFUNCTION()
	void RotateCubeTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRotation, TargetRotation, CurrentValue));
	}

	UFUNCTION()
	void RotateCubeTimelineFinished(float CurrentValue)
	{
		// for(auto Player : BlockedPlayers)
		// {
		// 	Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		// 	Player.UnblockCapabilities(CapabilityTags::Movement, this);
		// }
		
		BlockedPlayers.Empty();
	}
}