
enum EOutputType
{
	Texture,
	Material,
}
// This component is responsible for running a simulation from a starting condition.
// Influencing the simulation should be handled by other components talking to this one.

// All offscreen simulations should use this so that we can draw them for debugging and stuff
class UTextureSimulationComponent : UActorComponent
{
	UPROPERTY(Category = "zzInternal")
	UMaterialParameterCollection WorldShaderParameters = Asset("/Game/MasterMaterials/WorldParameters/WorldParameters.WorldParameters");
	
	UPROPERTY(Category = "Input")
	int SimulationWidth = 512;
	UPROPERTY(Category = "Input")
	int SimulationHeight = 512;
	
	
	UPROPERTY(Category = "Input")
	bool LimitFramerate = true;
	UPROPERTY(Category = "Input")
	int MaxFramerate = 30;

	UPROPERTY(Category = "zzInternal")
	float TimeToNextFrame = 0;

	UPROPERTY(Category = "Output")
	EOutputType OutputType;
	UPROPERTY(Category = "Output", Meta = (EditCondition="OutputType == EOutputType::Texture", EditConditionHides))
	UTextureRenderTarget2D OutputTexture;
	UPROPERTY(Category = "Output", Meta = (EditCondition="OutputType == EOutputType::Material", EditConditionHides))
    UMaterialInstanceDynamic OutputMaterial;


	UPROPERTY(Category = "Input")
	UMaterialInterface StartSimulationMaterial;
	UPROPERTY(Category = "Input")
	UMaterialInterface UpdateSimulationMaterial;


	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic StartSimulationMaterialDynamic;
	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic UpdateSimulationMaterialDynamic;


	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D SimulationSwapTarget1;
	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D SimulationSwapTarget2;

	
	UPROPERTY(Category = "zzInternal")
	UMaterialInterface SimulationCopyMaterial = Asset("/Game/Blueprints/Environment/GpuSimulations/Water/Simulation_Copy.Simulation_Copy");
	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic SimulationCopyMaterialDynamic;
	
	UPROPERTY(Category = "zzInternal")
	UMaterialInterface SimulationDrawCircleMaterial = Asset("/Game/Blueprints/Environment/GpuSimulations/Water/Simulation_DrawCircle.Simulation_DrawCircle");
	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic SimulationDrawCircleMaterialDynamic;
	
	void CopyTexture(UTextureRenderTarget2D FromThis, UTextureRenderTarget2D ToThis)
	{
		SimulationCopyMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", FromThis);
		Rendering::DrawMaterialToRenderTarget(ToThis, SimulationCopyMaterialDynamic);
	}

	void DrawCircleToSimulation(float X = 0.5, float Y = 0.5, float Radius = 0.5, FLinearColor TargetValue = FLinearColor(1, 1, 1, 1), FLinearColor PerChannelAlpha = FLinearColor(1, 1, 1, 1))
	{
		SimulationDrawCircleMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", SimulationSwapTarget2);
		
		SimulationDrawCircleMaterialDynamic.SetScalarParameterValue(n"X", X);
		SimulationDrawCircleMaterialDynamic.SetScalarParameterValue(n"Y", Y);
		SimulationDrawCircleMaterialDynamic.SetScalarParameterValue(n"Radius", Radius);
		
		SimulationDrawCircleMaterialDynamic.SetVectorParameterValue(n"TargetValue", TargetValue);
		SimulationDrawCircleMaterialDynamic.SetVectorParameterValue(n"PerChannelAlpha", PerChannelAlpha);
		
		Rendering::DrawMaterialToRenderTarget(SimulationSwapTarget1, SimulationDrawCircleMaterialDynamic);

		SimulationDrawCircleMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", SimulationSwapTarget1);
		Rendering::DrawMaterialToRenderTarget(SimulationSwapTarget2, SimulationDrawCircleMaterialDynamic);
	}
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		StartSimulationMaterialDynamic = Material::CreateDynamicMaterialInstance(StartSimulationMaterial);
		UpdateSimulationMaterialDynamic = Material::CreateDynamicMaterialInstance(UpdateSimulationMaterial);
		SimulationCopyMaterialDynamic = Material::CreateDynamicMaterialInstance(SimulationCopyMaterial);
		SimulationDrawCircleMaterialDynamic = Material::CreateDynamicMaterialInstance(SimulationDrawCircleMaterial);

		SimulationSwapTarget1 = Rendering::CreateRenderTarget2D(SimulationWidth, SimulationHeight, ETextureRenderTargetFormat::RTF_RGBA16f);
		SimulationSwapTarget2 = Rendering::CreateRenderTarget2D(SimulationWidth, SimulationHeight, ETextureRenderTargetFormat::RTF_RGBA16f);
	}



	int count = 0;
    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Initialize Simulation
		if(count < 4)
		{
			count++;
			Rendering::DrawMaterialToRenderTarget(SimulationSwapTarget1, StartSimulationMaterialDynamic);
			Rendering::DrawMaterialToRenderTarget(SimulationSwapTarget2, StartSimulationMaterialDynamic);
			CopyTexture(SimulationSwapTarget2, OutputTexture);
			return;
		}

		TimeToNextFrame -= DeltaTime;
		
		//if(TimeToNextFrame < 0 && LimitFramerate)
		{
			TimeToNextFrame = 1.0f / MaxFramerate;

			// Swap
			UTextureRenderTarget2D Temp = SimulationSwapTarget1;
			SimulationSwapTarget1 = SimulationSwapTarget2;
			SimulationSwapTarget2 = Temp;

			// Update Simulation
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", SimulationSwapTarget1);
			Rendering::DrawMaterialToRenderTarget(SimulationSwapTarget2, UpdateSimulationMaterialDynamic);

			// Generate Output
			if(OutputType == EOutputType::Texture)
			{
				CopyTexture(SimulationSwapTarget2, OutputTexture);
			}
			else if(OutputType == EOutputType::Material)
			{
				UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", SimulationSwapTarget1);
			}
		}
	}
}