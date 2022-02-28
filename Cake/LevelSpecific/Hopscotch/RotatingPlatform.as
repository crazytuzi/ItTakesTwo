import Cake.LevelSpecific.Hopscotch.NumberCube;

event void FRotatingPlatformSignature();

class ARotatingPlatform : AHazeActor
{
    UPROPERTY(DefaultComponent, Attach = RootComponent)
    USceneComponent ComponentToRotate;

    UPROPERTY()
    int NumberOfCubes;
    default NumberOfCubes = 4;

    UPROPERTY()
    float Radius;
    default Radius = 650.f;

    UPROPERTY()
    float Spinrate;
    default Spinrate = 15.f;

    UPROPERTY()
    EHopScotchNumber HopscotchNumberToSpawn;

    UPROPERTY()
    UStaticMesh NewMesh;

    UPROPERTY()
    TArray<UMaterialInterface> MaterialArray;
    
    UPROPERTY()
    TArray<UStaticMeshComponent> StaticMeshArray;

	UPROPERTY()
	FHazeTimeLike ShowCubesTimeline;
	default ShowCubesTimeline.Duration = 1.f;
    
    UPROPERTY()
    TArray<FVector> CubePositionArray;

    UPROPERTY()
    TSubclassOf<ANumberCube> ClassToSpawn;

    UPROPERTY()
    bool bShouldBeHidden;

    UPROPERTY()
    bool bShouldBeEmissive;

    UPROPERTY()
    bool bShouldTilt;

    UPROPERTY()
    bool bShouldBounce;

    UPROPERTY()
    bool bShouldGlow;

	UPROPERTY()
	FRotatingPlatformSignature CubesFinishedSpawning;

    UStaticMeshComponent StaticMeshComponent;

    float CubePositionMultiplier;
    default CubePositionMultiplier = 2000.f;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        CubePositionArray.Empty();
        StaticMeshArray.Empty();

        // Creates StaticMeshComponents in a circle based on the NumberOfCubes

        for (int i = 0; i < NumberOfCubes + 1; i++)
        {
            float Y;
            Y = i * (360 / NumberOfCubes);

            FRotator Rot = FRotator(Y, 0, 0);

            FVector Forward = Rot.GetForwardVector();
            
            CubePositionArray.Add(Forward);

            FName ComponentName = FName("Cube" + i);

            StaticMeshComponent = UStaticMeshComponent::Create(this, ComponentName);
            StaticMeshComponent.SetRelativeLocation(FVector(Forward * Radius));
            StaticMeshComponent.SetRelativeScale3D(FVector(1.f, 1.f, 1.f));
            StaticMeshComponent.AttachToComponent(ComponentToRotate, n"", EAttachmentRule::KeepRelative);
            StaticMeshComponent.SetStaticMesh(NewMesh);
            StaticMeshComponent.SetMaterial(1, MaterialArray[HopscotchNumberToSpawn]);
			StaticMeshComponent.CastShadow = false;
			StaticMeshComponent.SetAbsolute(false, false, true);
            StaticMeshArray.Add(StaticMeshComponent);
        }
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		ShowCubesTimeline.BindUpdate(this, n"ShowCubesTimelineUpdate");
		ShowCubesTimeline.BindFinished(this, n"ShowCubesTimelineFinished");

		if (bShouldBeHidden)
		{
			SetActorTickEnabled(false);
			
			for (UStaticMeshComponent MeshComp : StaticMeshArray)
			{
				MeshComp.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", 0.f);
				
			}
		}

		ComponentToRotate.SetWorldScale3D(FVector(4.f, 4.f, 4.f));
    }

    UFUNCTION(BlueprintOverride)
    void Tick (float Delta)
    {
        ComponentToRotate.AddLocalRotation(FRotator(Spinrate * GetActorDeltaSeconds(), 0.f, 0.f));
    }

	UFUNCTION()
	void ShowCubes()
	{
		ShowCubesTimeline.PlayFromStart();
	}

	UFUNCTION()
	void ShowCubesTimelineUpdate(float CurrentValue)
	{

		ComponentToRotate.SetWorldScale3D(FMath::Lerp(FVector(4.f, 4.f, 4.f), FVector(1.f, 1.f, 1.f), CurrentValue));

		for (UStaticMeshComponent MeshComp : StaticMeshArray)
		{
			MeshComp.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", CurrentValue);
		}
	}

	UFUNCTION()
	void ShowCubesTimelineFinished(float CurrentValue)
	{
		CubesFinishedSpawning.Broadcast();
	}	

	
}