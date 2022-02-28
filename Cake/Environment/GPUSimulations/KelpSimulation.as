import Cake.Environment.GPUSimulations.Simulation;
import Vino.Audio.AudioActors.HazePlayerTriggeredSound;

class AKelpSimulation : ASimulation
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	//UPROPERTY()
	//int FoliageIndex = 0;

	UPROPERTY()
	UMaterialInterface DrawColumnMaterial;

	UPROPERTY()
	UMaterialInstanceDynamic DrawColumnMaterialDynamic;

	UPROPERTY()
	UTexture2D StartingCondition;

	UPROPERTY()
	AActor ExtraInfluenceActor;

	UPROPERTY()
	float KelpStrandHeight = 10000;

	UPROPERTY()
	float WindStrength = 15;

	UPROPERTY()
	float PlayerCollisionRadius = 200;

	UPROPERTY()
	float ExtraCollisionRadius = 750;

	UPROPERTY()
	UStaticMesh Mesh = Asset("/Game/Blueprints/Environment/GpuSimulations/Kelp/Kelp1.Kelp1");

	UPROPERTY(Category = "System")
	UHierarchicalInstancedStaticMeshComponent KelpMesh;
	
	UPROPERTY(Category = "System")
    UMaterialInstanceDynamic MeshMaterialInstanceDynamic;
	
	float Height = 16;
	float Width = 50;

	UPROPERTY(Category = "System")
	TArray <AHazePlayerTriggeredSound> KelpTriggers;

	// todo: hide this setting from users, should only allow box type,
	UPROPERTY(Category = "Sound Trigger")
	FHazeShapeSettings ShapeSettings;
	default ShapeSettings.Type = EHazeShapeType::Box;

	UFUNCTION(CallInEditor, Category = "Sound Trigger")
	void GenerateTriggerVolumes()
	{
		KelpMesh = FoliageInfo::GetFoliageMesh(this, Mesh, 0);
		if(KelpMesh == nullptr)
			return;

		FBox BoundingBox = Mesh.GetBoundingBox(); // Get the bounds for the mesh used by the kelp system,

		// Clear previously created Kelp Triggers by this class,
		for(AHazePlayerTriggeredSound Trigger : this.KelpTriggers)
		{
			Trigger.DestroyActor();
		}

		KelpTriggers.Empty(); // and empty the array, not sure if this is actually all that is required,

		// Get the extends for the bounding box and assing to the brush cube volume,
		ShapeSettings.BoxExtends = BoundingBox.Extent;

		for(int i = 0; i < KelpMesh.InstanceCount; i++)
		{
			// Get the transform for the current instance,
			FTransform Transform;
			KelpMesh.GetInstanceTransform(i, Transform, true);

			// The Box from the Brush gets created at root of the kelp, so we want to offset this
			// to match the placed actors in world by getting their bb center and scaling to the
			// current instance,
			FVector Offset = FVector(0.0, 0.0, BoundingBox.Center.Z * Transform.Scale3D.Z);

			// Spawn the sound volume for the current kelp,
			AHazePlayerTriggeredSound KelpTrigger = Cast<AHazePlayerTriggeredSound>(SpawnActor(
				AHazePlayerTriggeredSound::StaticClass(), 
				Transform.Location + Offset, 
				Transform.Rotator(), 
				FName("KelpTriggerSound_"+i), 
				false, 
				Level
			));

			// Create the brush component for our volume actor and apply the scale for current instance,
			Shape::CreateBrush(KelpTrigger, ShapeSettings);
			KelpTrigger.BrushComponent.SetWorldScale3D(Transform.Scale3D);

			KelpTriggers.Add(KelpTrigger); // Add to our array so we keep track of volumes added,
		}
	}
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KelpMesh = FoliageInfo::GetFoliageMesh(this, Mesh, 0);

		if(KelpMesh == nullptr)
			return;
		
		Width = 1024;

		if(Width == 0)
			return;
		
		InitMaterials();
		
		InitSwapBuffer(Width, Height, ETextureRenderTargetFormat::RTF_RGBA16f);

		DrawColumnMaterialDynamic = Material::CreateDynamicMaterialInstance(DrawColumnMaterial);

		MeshMaterialInstanceDynamic = KelpMesh.CreateDynamicMaterialInstance(0);
		MeshMaterialInstanceDynamic.SetTextureParameterValue(n"SimulationTexture", SimulationBuffer.Target1);
		
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"WindStrength", WindStrength);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"KelpStrandHeight", KelpStrandHeight);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Height", Height);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Width", Width);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Index", 0);

		StartSimulationMaterialDynamic.SetScalarParameterValue(n"KelpStrandHeight", KelpStrandHeight);
		StartSimulationMaterialDynamic.SetScalarParameterValue(n"Height", Height);
		StartSimulationMaterialDynamic.SetScalarParameterValue(n"Width", Width);
		MeshMaterialInstanceDynamic.SetScalarParameterValue(n"KelpStrandHeight", KelpStrandHeight);
		MeshMaterialInstanceDynamic.SetScalarParameterValue(n"Height", Height);
		MeshMaterialInstanceDynamic.SetScalarParameterValue(n"Width", Width);
	}
	
	bool Initialized = false;

	void PokeColumnWithMaterial(UTextureRenderTarget2D From, UTextureRenderTarget2D To, int X, FLinearColor Color)
	{
		DrawColumnMaterialDynamic.SetScalarParameterValue(n"Width", KelpMesh.InstanceCount);
		DrawColumnMaterialDynamic.SetScalarParameterValue(n"X", X);
		DrawColumnMaterialDynamic.SetTextureParameterValue(n"PreviousFrame", From);
		DrawColumnMaterialDynamic.SetVectorParameterValue(n"Color", Color);
		Rendering::DrawMaterialToRenderTarget(To, DrawColumnMaterialDynamic);
	}

    UFUNCTION()
	void ResetTexture()
	{
		Rendering::ClearRenderTarget2D(SimulationBuffer.Target1, 	FLinearColor(0,0,0,0));
		Rendering::ClearRenderTarget2D(SimulationBuffer.Target2, 	FLinearColor(0,0,0,0));

		//FVector StreamingOffset = Progress::GetLevelStreamingOffset(GetLevel());
		//FLinearColor LevelOffset(StreamingOffset.X, StreamingOffset.Y, StreamingOffset.Z, 0.f);
		//StartSimulationMaterialDynamic.SetVectorParameterValue(n"LevelOffset", LevelOffset);
		//CopyRenderTargetStatic(StartingCondition, SimulationBuffer.Target1, StartSimulationMaterialDynamic);
		//CopyRenderTargetStatic(StartingCondition, SimulationBuffer.Target2, StartSimulationMaterialDynamic);
	}

	bool IsInitialzied()
	{
		return (SimulationBuffer.Target1 != nullptr &&
				SimulationBuffer.Target2 != nullptr &&
				MeshMaterialInstanceDynamic != nullptr &&
				StartSimulationMaterialDynamic != nullptr &&
				KelpMesh != nullptr &&
				Width > 0);
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		if(!Initialized)
		{
			ResetTexture();
			MeshMaterialInstanceDynamic.SetScalarParameterValue(n"Initialized", 1.0f);
			Initialized = true;
			return;
		}

		if(!IsInitialzied())
			return;

		
		FVector location = FVector(0,0,0);
		if(ExtraInfluenceActor != nullptr)
		{
			location = ExtraInfluenceActor.GetActorLocation();
			UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"PushInput1", FLinearColor(location.X, location.Y, location.Z, ExtraCollisionRadius));
		}
		else
		{
			UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"PushInput1", FLinearColor(0, 0, 0, 1));
		}

		location = Game::GetMay().GetActorLocation();
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"PushInput2", FLinearColor(location.X, location.Y, location.Z, PlayerCollisionRadius));

		location = Game::GetCody().GetActorLocation();
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"PushInput3", FLinearColor(location.X, location.Y, location.Z, PlayerCollisionRadius));

		FVector StreamingOffset = Progress::GetLevelStreamingOffset(GetLevel());
		FLinearColor LevelOffset(StreamingOffset.X, StreamingOffset.Y, StreamingOffset.Z, 0.f);
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"LevelOffset", LevelOffset);
		UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"PreviousFrame", SimulationBuffer.Target1);
		UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"StartingCondition", StartingCondition);

		MeshMaterialInstanceDynamic.SetTextureParameterValue(n"SimulationTexture", SimulationBuffer.Target2);

		SwapAndDraw(UpdateSimulationMaterialDynamic, SimulationBuffer);
    }
}