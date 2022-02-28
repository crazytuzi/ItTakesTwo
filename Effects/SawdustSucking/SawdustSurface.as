import Rice.RenderTextureDrawing.RenderTextureDrawing;

class ASawdustSurfaceActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Default;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Mesh;

    UPROPERTY()
    AActor Sucker;

    UPROPERTY(DefaultComponent)
    UNiagaraComponent SuckingEffect;
    
    TArray<bool> EatenPoints;

    UPROPERTY()
    UTexture2D StartingTexture;

    UPROPERTY()
    float SuckPushStrength = 0.5;

    UPROPERTY()
    float SuckPullStrength = 0.5;

    UPROPERTY()
    float SuckRadius = 0.2;

    UPROPERTY()
    UMaterial VectorStampToDraw;
    UMaterialInstanceDynamic VectorStampToDrawDynamic;

    int CPUDataResolution = 20;
    UMaterialInstanceDynamic Material;
    UTextureRenderTarget2D HeightmapRenderTarget;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        //DrawTexture(HeightmapRenderTarget, StartingTexture, 0, 0, 1, 1);
    }

	bool& GetEatenPointData(int x, int y)
	{
		return EatenPoints[(y * CPUDataResolution) + x];
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        
        VectorStampToDrawDynamic = Material::CreateDynamicMaterialInstance(VectorStampToDraw);
        Material = Mesh.CreateDynamicMaterialInstance(0);
        HeightmapRenderTarget = Rendering::CreateRenderTarget2D(256, 256, ETextureRenderTargetFormat::RTF_RGBA16f);
        
        Material.SetTextureParameterValue(FName("RenderHeight"), HeightmapRenderTarget);

        DrawTexture(HeightmapRenderTarget, StartingTexture, 0, 0, 1, 1);

		EatenPoints.SetNum(CPUDataResolution * CPUDataResolution);
        for (int i = 0, Count = EatenPoints.Num(); i < Count; ++i)
			EatenPoints[i] = true;
    }

    void DebugDrawVector(FVector Location, FVector Vector, int color = 0)
    {
        int Color1 = color + 1;
        int Color2 = color + 2;
        int Color3 = color + 3;
        FVector vec = Vector;
        System::DrawDebugLine(Location, Location + vec, FLinearColor((Color1 % 3)/2.0, (Color2 % 3)/2.0, (Color3 % 3)/2.0, 0), 0, 5);
    }

    float PlaneWorldSize = 800;

    float SuckingLeft = 0.5;
    float timer = 0;
    float SimulationStepsPerSecond = 30;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
        if(!System::IsValid(Sucker))
            return;

        FVector LocalSuckerLocation = Default.GetWorldTransform().InverseTransformPosition(Sucker.GetActorLocation());

        // Swizzle
        LocalSuckerLocation = FVector(-LocalSuckerLocation.Y, LocalSuckerLocation.X, LocalSuckerLocation.Z);

        LocalSuckerLocation = LocalSuckerLocation / PlaneWorldSize + 0.5;
        Material.SetVectorParameterValue(FName("SuckLocation"), FLinearColor(LocalSuckerLocation.X, LocalSuckerLocation.Y, 0, 0));
        

        timer -= DeltaSeconds;
        if(timer < 0)
        {
            float PushStrength = 0.5;
            timer = 1.0 / SimulationStepsPerSecond;
            VectorStampToDrawDynamic.SetScalarParameterValue(FName("SuckPushStrength"), SuckPushStrength);
            VectorStampToDrawDynamic.SetScalarParameterValue(FName("SuckPullStrength"), SuckPullStrength);
            
            DrawMaterial(HeightmapRenderTarget, VectorStampToDrawDynamic, LocalSuckerLocation.X, LocalSuckerLocation.Y, SuckRadius, SuckRadius, true);
            //DrawMaterial(HeightmapRenderTarget, HeightStampToDraw, LocalSuckerLocation.X, LocalSuckerLocation.Y, 0.1, 0.1, true);

            //DrawTexture(HeightmapRenderTarget, VectorStamp, LocalSuckerLocation.X, LocalSuckerLocation.Y, 0.1, 0.1, true,
            //FLinearColor(-PushStrength, -PushStrength, -PushStrength, 1), EBlendMode::BLEND_Additive);
        }

        int TextureLocationX = FMath::Clamp(LocalSuckerLocation.X * CPUDataResolution, 0, CPUDataResolution);
        int TextureLocationY = FMath::Clamp(LocalSuckerLocation.Y * CPUDataResolution, 0, CPUDataResolution);

        if(GetEatenPointData(TextureLocationX, TextureLocationY))
        {
            GetEatenPointData(TextureLocationX, TextureLocationY) = false;
            SuckingLeft += 0.5;
        }
        
        // Particle Effect
        SuckingLeft -= DeltaSeconds;
        SuckingLeft = FMath::Clamp(SuckingLeft, 0.01, 1.0);

        SuckingEffect.SetNiagaraVariableFloat("User.SpawnRate", SuckingLeft);

        SuckingEffect.SetWorldLocation(Sucker.GetActorLocation() - FVector(0,0,30));
        
        return;
    }
};