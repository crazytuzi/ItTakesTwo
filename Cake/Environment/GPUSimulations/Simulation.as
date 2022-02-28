import Rice.RenderTextureDrawing.RenderTextureDrawing;

struct SwapBuffer
{
	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D Target1;

	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D Target2;

	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D ActiveTarget;
}

class ASimulation : AHazeActor
{
	UPROPERTY(Category = "Options")
	UMaterialInterface UpdateSimulationMaterial = Asset("/Game/Blueprints/Environment/GpuSimulations/Wither/UpdateWitherMaterial.UpdateWitherMaterial");

	UPROPERTY(Category = "Options")
	UMaterialInterface StartSimulationMaterial = Asset("/Game/Blueprints/Environment/GpuSimulations/Wither/UpdateWitherMaterial.UpdateWitherMaterial");

	int SizeX;
	int SizeY;
	
	UPROPERTY(Category = "zzInternal")
	UMaterial CopyTextureMaterial = Asset("/Game/Blueprints/Environment/GpuSimulations/Water/Simulation_Copy.Simulation_Copy");
	
	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic CopyTextureMaterialDynamic;

	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic UpdateSimulationMaterialDynamic;

	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic StartSimulationMaterialDynamic;

	UPROPERTY(Category = "zzInternal")
	SwapBuffer SimulationBuffer;

	void DrawTextureToRendertarget(UTextureRenderTarget2D RenderTarget, UTexture Texture, float x, float y, float width, float height, FLinearColor Color, EBlendMode Blend = EBlendMode::BLEND_Translucent, float Rotation = 0)
	{
		UCanvas Canvas;
		FVector2D CanvasSize;
		FDrawToRenderTargetContext Context;
		Rendering::BeginDrawCanvasToRenderTarget(RenderTarget, Canvas, CanvasSize, Context);
		Canvas.DrawTexture(Texture, FVector2D(x * RenderTarget.SizeX, y * RenderTarget.SizeY), FVector2D(width * RenderTarget.SizeX, height * RenderTarget.SizeY), FVector2D(0, 0), FVector2D(1, 1), Color, Blend, Rotation);
		
		Rendering::EndDrawCanvasToRenderTarget(Context);
	}
	void DrawTextureToRendertarget(SwapBuffer RenderTarget, UTexture Texture, float x, float y, float width, float height, FLinearColor Color, EBlendMode Blend = EBlendMode::BLEND_Translucent, float Rotation = 0)
	{
		DrawTextureToRendertarget(RenderTarget.Target1, Texture, x, y, width, height, Color, Blend, Rotation);
		DrawTextureToRendertarget(RenderTarget.Target2, Texture, x, y, width, height, Color, Blend, Rotation);
	}

	void DrawTextureToRendertargetCentered(UTextureRenderTarget2D RenderTarget, UTexture Texture, float x, float y, float width, float height, FLinearColor Color, EBlendMode Blend = EBlendMode::BLEND_Translucent, float Rotation = 0)
	{
		DrawTextureToRendertarget(RenderTarget, Texture, x - width * 0.5f, y - height * 0.5f, width, height, Color, Blend, Rotation);
	}
	void DrawTextureToRendertargetCentered(SwapBuffer RenderTarget, UTexture Texture, float x, float y, float width, float height, FLinearColor Color, EBlendMode Blend = EBlendMode::BLEND_Translucent, float Rotation = 0)
	{
		DrawTextureToRendertargetCentered(RenderTarget.Target1, Texture, x, y, width, height, Color, Blend, Rotation);
		DrawTextureToRendertargetCentered(RenderTarget.Target2, Texture, x, y, width, height, Color, Blend, Rotation);
	}

	void CopyTexture(UTextureRenderTarget2D FromThis, UTextureRenderTarget2D ToThis)
	{
		CopyTextureMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", FromThis);
		Rendering::DrawMaterialToRenderTarget(ToThis, CopyTextureMaterialDynamic);
	}

	void SwapAndDraw(UMaterialInstanceDynamic DrawMaterial, SwapBuffer& Buffer)
	{
		// Swap
		UTextureRenderTarget2D Temp = Buffer.Target1;
		Buffer.Target1 = Buffer.Target2;
		Buffer.Target2 = Temp;
		
		// Draw
		DrawMaterial.SetTextureParameterValue(n"PreviousFrame", Buffer.Target1);
		DrawMaterial.SetScalarParameterValue(n"SimulationSizeX", SizeX);
		DrawMaterial.SetScalarParameterValue(n"SimulationSizeY", SizeY);
		
		DrawMaterial.SetScalarParameterValue(n"SimulationExtra", 0.0f);
		Rendering::DrawMaterialToRenderTarget(Buffer.Target2, DrawMaterial);
		//CurrentSimulationTarget = Buffer.Target2;
		Buffer.ActiveTarget = Buffer.Target2;
	}

    UFUNCTION()
	void UpdateSwapBuffer()
	{
		SwapAndDraw(UpdateSimulationMaterialDynamic, SimulationBuffer);
	}

	UTextureRenderTarget2D InitRenderTarget(int SizeX, int SizeY, ETextureRenderTargetFormat Format = ETextureRenderTargetFormat::RTF_RGBA8)
	{
		UTextureRenderTarget2D Result;
		Result = Rendering::CreateRenderTarget2D(SizeX, SizeY, Format);
		Result.AddressX = TextureAddress::TA_Clamp;
		Result.AddressY = TextureAddress::TA_Clamp;
		return Result;
	}

    UFUNCTION()
	void InitMaterials()
	{
		UpdateSimulationMaterialDynamic = Material::CreateDynamicMaterialInstance(UpdateSimulationMaterial);
		StartSimulationMaterialDynamic = Material::CreateDynamicMaterialInstance(StartSimulationMaterial);
		CopyTextureMaterialDynamic = Material::CreateDynamicMaterialInstance(CopyTextureMaterial);
	}

    UFUNCTION()
	SwapBuffer InitSwapBuffer(int SizeX, int SizeY, ETextureRenderTargetFormat Format = ETextureRenderTargetFormat::RTF_RGBA8)
	{
		SwapBuffer s = SwapBuffer();
		
		this.SizeX = SizeX;
		this.SizeY = SizeY;

		s.Target1 = Rendering::CreateRenderTarget2D(SizeX, SizeY, Format);
		s.Target1.AddressX = TextureAddress::TA_Clamp;
		s.Target1.AddressY = TextureAddress::TA_Clamp;
		s.Target2 = Rendering::CreateRenderTarget2D(SizeX, SizeY, Format);
		s.Target2.AddressX = TextureAddress::TA_Clamp;
		s.Target2.AddressY = TextureAddress::TA_Clamp;
		s.ActiveTarget = s.Target2;
	
		SwapAndDraw(StartSimulationMaterialDynamic, s);
		SimulationBuffer = s;
		return s;
	}

	void PokePixel(UTextureRenderTarget2D RenderTarget, int X, int Y, FLinearColor Color)
	{
		UCanvas Canvas;
		FVector2D CanvasSize;
		FDrawToRenderTargetContext Context;
		Rendering::BeginDrawCanvasToRenderTarget(RenderTarget, Canvas, CanvasSize, Context);
		
		Canvas.DrawPolygon(nullptr, FVector2D(X,Y+0.5f), FVector2D(0.9f, 1.0f), 3, Color);
		
		Rendering::EndDrawCanvasToRenderTarget(Context);
	}

	// This function is busted on the PS4 Pro, PS5 and maybe base PS4 but haven't tested. YEET.
	//void PokeColumn(UTextureRenderTarget2D RenderTarget, int X, FLinearColor Color)
	//{
	//	UCanvas Canvas;
	//	FVector2D CanvasSize;
	//	FDrawToRenderTargetContext Context;
	//	Rendering::BeginDrawCanvasToRenderTarget(RenderTarget, Canvas, CanvasSize, Context);
	//	
	//	Canvas.DrawLine(FVector2D(X+1, 0), FVector2D(X+1, 2000), 1, Color);
	//	
	//	Rendering::EndDrawCanvasToRenderTarget(Context);
	//}
	
}