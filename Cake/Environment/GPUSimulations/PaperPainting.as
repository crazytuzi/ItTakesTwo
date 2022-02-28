import Rice.RenderTextureDrawing.RenderTextureDrawing;
import Vino.Movement.Components.MovementComponent;
import Cake.Environment.GPUSimulations.Simulation;
import Vino.Characters.PlayerCharacter;


struct PlayerPaintData
{
	UPROPERTY()
	float Opacity = 0.f;

	UPROPERTY()
	float TempOpacity = 0.f;

	UPROPERTY()
	float BrushSize= 1.0f;
	
	// Rendertarget containing the color the player is currently painting
	UPROPERTY()
	UTextureRenderTarget2D PaintTarget;

	UPROPERTY()
	FVector LastPos;

	UPROPERTY()
	bool bPlayerIsInPool = false;
}


class APaperPainting : ASimulation
{
	UPROPERTY(Category = "Options")
	TArray<PlayerPaintData> PlayerData;

	UPROPERTY(Category = "Options")
	AStaticMeshActor PaintMesh;

	UPROPERTY(Category = "Options")
	UAkAudioEvent GroundPoundSound;

	UPROPERTY(Category = "Options")
	bool AlwaysPaint = false;

	UPROPERTY(Category = "Options")
	AActor PaperMesh;

	UPROPERTY(Category = "Options")
	AStaticMeshActor VelocityMesh;

	UPROPERTY(Category = "Options")
	AStaticMeshActor PictureFrameMash;

	UPROPERTY(Category = "zzInternal")
	UStaticMeshComponent PrinterPaperMesh;

	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic PrinterPaperMeshMaterial;

	UPROPERTY(Category = "zzInternal")
	UMaterialInterface DrawCenteredMaterial;

	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic DrawCenteredMaterialDynamic;

	UPROPERTY(Category = "Options")
	UTexture2D StartPaintTexture;

	UPROPERTY(Category = "Options")
	UTexture2D StartVelocityTexture;

	UPROPERTY(Category = "Options")
	UTexture2D StartPaperTexture;

	UPROPERTY(Category = "Options")
	UTexture2D SmudgeTexture;

	UPROPERTY(Category = "Options")
	UTexture2D AddPaintToPoolTexture;

	UPROPERTY(Category = "Options")
	TArray<UTexture2D> PaintToPoolTextures;

	UPROPERTY(Category = "Options")
	UTexture2D PaintSplashVel1;
	
	UPROPERTY(Category = "Options")
	UTexture2D PaintSplashVel2;
	
	UPROPERTY(Category = "Options")
	float Damping = 10.0f;

	UPROPERTY(Category = "Options")
	float Diffusion = 1.0f;

	UPROPERTY(Category = "Options")
	float FlowSpeed = 1.0f;

	UPROPERTY(Category = "Options")
	float PaperPaintSize = 0.05f;

	UPROPERTY(Category = "Options")
	float SmugdeSize = 0.1f;

	UPROPERTY(Category = "Options")
	float SmugdeStrength = 8.0f;

	UPROPERTY(Category = "Options")
	bool Turbulence = false;


	UPROPERTY(Category = "Options")
	float PaperObjectSize = 1800.0f;

	UPROPERTY(Category = "Options")
	float PaintObjectSize = 50.0f;

	UPROPERTY(Category = "Options")
	float AlwaysPaintFadeTime = 2.0f;


	UPROPERTY(Category = "Options")
	UTexture2D PaperBrushBlack;

	UPROPERTY(Category = "Options")
	UTexture2D PaperBrushWhite;

	UPROPERTY(Category = "Options")
	bool PaintPlayer = true;

	UPROPERTY(Category = "zzInternal")
	UTexture2D Black;

	UPROPERTY(Category = "zzInternal")
	UTexture2D White;

	UPROPERTY(Category = "Options")
	int SimulationTargetSize = 128;





	UPROPERTY(Category = "zzInternalGenerated")
	UMaterialInstanceDynamic PaintMeshSurfaceMaterialDynamic;

	UPROPERTY(Category = "zzInternalGenerated")
	UMaterialInstanceDynamic PaperMeshSurfaceMaterialDynamic;

	UPROPERTY(Category = "zzInternalGenerated")
	UMaterialInstanceDynamic VelocityMeshSurfaceMaterialDynamic;

	UPROPERTY(Category = "zzInternalGenerated")
	SwapBuffer PaintVelocityBuffer;

	UPROPERTY(Category = "zzInternalGenerated")
	SwapBuffer PaintColorBuffer;


	UPROPERTY(Category = "zzInternalGenerated")
	UTextureRenderTarget2D PlaceholderTarget;

	UPROPERTY(Category = "zzInternalGenerated")
	UTextureRenderTarget2D OpacityBrushTarget;

	UPROPERTY(Category = "zzInternalGenerated") // current one
	UTextureRenderTarget2D PaperPaintTarget;

	UPROPERTY(Category = "zzInternalGenerated")
	UTextureRenderTarget2D PaperPaintTarget1;

	UPROPERTY(Category = "zzInternalGenerated")
	UTextureRenderTarget2D PaperPaintTarget2;

	UPROPERTY(Category = "zzInternalGenerated")
	UMaterialInterface PaperPaintMaterial;

	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D WitherTexture;

	UPROPERTY(Category = "zzInternalGenerated")
	UMaterialInstanceDynamic PaperPaintMaterialDynamic;
	
	UPROPERTY(Category = "Options")
	UTexture2D BlobTexture;

	UPROPERTY(Category = "zzInternalGenerated")
	UTextureRenderTarget2D PictureFramePaintTarget;

	UPROPERTY(Category = "zzInternalGenerated")
	UTextureRenderTarget2D PictureFramePaintTarget2;

	UFUNCTION(CallInEditor)
	void CopyRectangle2()
	{
		CopyRectangle(FVector(3469.00, 59193.00, -80.00), 0.250000, 0.350000);
	}

	UFUNCTION(CallInEditor)
	void CopyRectangle(FVector WorldPosition, float Width, float Height)
	{
		FVector LocalPos = GetLocalPos(PaperMesh, WorldPosition, PaperObjectSize);
		FVector size = FVector(Width, Height, 1);
		
		FVector NewPos = ((-LocalPos) / size) + 0.5f;
		FVector NewSize = FVector::OneVector / size;
		
		DrawTextureToRendertarget(PictureFramePaintTarget, PaperPaintTarget1, NewPos.X, NewPos.Y, NewSize.X, NewSize.Y, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(WitherTexture, PaperPaintTarget1, NewPos.X, NewPos.Y, NewSize.X, NewSize.Y, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
	
		
		//ClearRectangleOnPaper(WorldPosition, Width, Height, FLinearColor(1, 1, 1, 1));
	}
	
	UFUNCTION(CallInEditor)
	void PasteToPictureFrame()
	{
		auto mat = PictureFrameMash.StaticMeshComponent.CreateDynamicMaterialInstance(0);
		mat.SetTextureParameterValue(n"Pictureframe", PictureFramePaintTarget);
		UTextureRenderTarget2D temp = PictureFramePaintTarget;
		PictureFramePaintTarget = PictureFramePaintTarget2;
		PictureFramePaintTarget2 = temp;
	}
	
	// TODO: Implement and make it fade in with a wipe
	UFUNCTION()
	void CopyRectangleToPictureFrame(FVector WorldPosition, float Width, float Height)
	{
		FVector LocalPos = GetLocalPos(PaperMesh, WorldPosition, PaperObjectSize);
		FVector size = FVector(Width, Height, 1);
		
		FVector NewPos = ((-LocalPos) / size) + 0.5f;
		FVector NewSize = FVector::OneVector / size;
		
		DrawTextureToRendertarget(PictureFramePaintTarget, PaperPaintTarget1, NewPos.X, NewPos.Y, NewSize.X, NewSize.Y, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		
		auto mat = PictureFrameMash.StaticMeshComponent.CreateDynamicMaterialInstance(0);
		mat.SetTextureParameterValue(n"Pictureframe", PictureFramePaintTarget);
	}

	UFUNCTION()
	void ClearRectangleOnPaper(FVector WorldPosition, float Width, float Height, FLinearColor Color)
	{
		FVector LocalPos = GetLocalPos(PaperMesh, WorldPosition, PaperObjectSize);
		DrawTextureToRendertargetCentered(PaperPaintTarget1, White, LocalPos.X, LocalPos.Y, Width, Height, Color, EBlendMode::BLEND_Opaque);
		DrawTextureToRendertargetCentered(PaperPaintTarget2, White, LocalPos.X, LocalPos.Y, Width, Height, Color, EBlendMode::BLEND_Opaque);
	}

    UFUNCTION(CallInEditor)
	void TestAddPaint()
	{
		AddPaintToPool(Game::GetMay().GetActorLocation(), 0.5f, FLinearColor(1,1,1,1), false, 0);
	}

    UFUNCTION()
	void AddPaintToPool(FVector WorldPosition, float Radius, FLinearColor Color, bool UseRandomTexture = false, float Rotation = 0)
	{
		FVector LocalPos = GetLocalPos(PaintMesh, WorldPosition, PaintObjectSize);
		if(UseRandomTexture && PaintToPoolTextures.Num() != 0)
			DrawTextureToRendertargetCentered(PaintColorBuffer, GetRandomTexture(), LocalPos.X, LocalPos.Y, Radius, Radius, Color, EBlendMode::BLEND_Translucent, Rotation);
		else
			DrawTextureToRendertargetCentered(PaintColorBuffer, AddPaintToPoolTexture, LocalPos.X, LocalPos.Y, Radius, Radius, Color, EBlendMode::BLEND_Translucent, Rotation);
	}

    UFUNCTION(CallInEditor)
	void Reset()
	{
		ClearEverything();
	}

    UFUNCTION()
	void AddPaintToPaper(FVector WorldPosition, float Radius, FLinearColor Color, float Rotation = 0)
	{
		FVector LocalPos = GetLocalPos(PaperMesh, WorldPosition, PaintObjectSize);
		DrawTextureToRendertargetCentered(PaperPaintTarget1, AddPaintToPoolTexture, LocalPos.X, LocalPos.Y, Radius, Radius, Color, EBlendMode::BLEND_Translucent, Rotation);
		DrawTextureToRendertargetCentered(PaperPaintTarget2, AddPaintToPoolTexture, LocalPos.X, LocalPos.Y, Radius, Radius, Color, EBlendMode::BLEND_Translucent, Rotation);
	}

	UTexture2D GetRandomTexture()
	{
		int Index = FMath::RandRange(0, PaintToPoolTextures.Num());

		if(Index != 0)
			Index--;
		
		return PaintToPoolTextures[Index];
	}

	// Reeeeeee. Need to do this expensive thing for it to work on the PS4.
    UFUNCTION()
	void DrawTextureToRendertargetCentered_PS4Safe(SwapBuffer& RenderTarget, UTexture Texture, float x, float y, float width, float height, FLinearColor Color, EBlendMode Blend = EBlendMode::BLEND_Translucent, float Rotation = 0)
	{
		DrawCenteredMaterialDynamic.SetScalarParameterValue(n"Width", width);
		DrawCenteredMaterialDynamic.SetScalarParameterValue(n"height", height);
		DrawCenteredMaterialDynamic.SetScalarParameterValue(n"X", x);
		DrawCenteredMaterialDynamic.SetScalarParameterValue(n"Y", y);
		DrawCenteredMaterialDynamic.SetVectorParameterValue(n"Color", Color);
		DrawCenteredMaterialDynamic.SetTextureParameterValue(n"Texture", Texture);

		SwapAndDraw(DrawCenteredMaterialDynamic, RenderTarget);
	}

    UFUNCTION()
	void GroundPound(AHazePlayerCharacter Player, bool IsInPool, FVector WorldPosition, float Rotation = 0)
	{
		// Pool
		float Radius = 0.75f;
		FVector LocalPos = GetLocalPos(PaintMesh, WorldPosition, PaintObjectSize);
		DrawTextureToRendertargetCentered_PS4Safe(PaintVelocityBuffer, PaintSplashVel1, LocalPos.X, LocalPos.Y, Radius, Radius, FLinearColor(-10, -10, 1, 1), EBlendMode::BLEND_Additive, Rotation);
		//DrawTextureToRendertargetCentered(PaintVelocityBuffer, PaintSplashVel2, LocalPos.X, LocalPos.Y, Radius, Radius, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Additive, Rotation);

		// Paint
		PaintOnPaper(Player.GetActorLocation(), GetPlayerPaintData(Player).PaintTarget, GetPlayerPaintData(Player).Opacity, 3.0 * PaperPaintSize, GetPlayerPaintData(Player).bPlayerIsInPool);
		
		// Clear Ground pounded player paint if not in pool
		if(!IsInPool)
		{
			ClearPlayerPaint(Player);
		}

		// Play sound
		if(GroundPoundSound != nullptr && IsInPool)
			UHazeAkComponent::HazePostEventFireForget(GroundPoundSound, Player.GetActorTransform());
	}
	

    UFUNCTION()
	void SetPlayerBrushSize(AHazePlayerCharacter Player, float BrushSize)
	{
		GetPlayerPaintData(Player).BrushSize = BrushSize;
	}

    UFUNCTION()
	void SetPlayerBrushOpacity(AHazePlayerCharacter Player, float Opacity)
	{
		GetPlayerPaintData(Player).Opacity = Opacity;
	}
	
    UFUNCTION()
	void ClearPlayerPaint(AHazePlayerCharacter Player)
	{
		SetPlayerBrushSize(Player, 0.f);
		SetPlayerBrushOpacity(Player, 0.0f);
		DrawTextureToRendertarget(GetPlayerPaintData(Player).PaintTarget, Black, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);

		DrawTextureToRendertarget(PlaceholderTarget, Black, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(OpacityBrushTarget, Black, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
	}

    UFUNCTION()
	void ClearEverything()
	{
		DrawTextureToRendertarget(PaperPaintTarget1, StartPaperTexture, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(PaperPaintTarget2, StartPaperTexture, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(PaintColorBuffer, StartPaintTexture, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(PaintVelocityBuffer, StartVelocityTexture, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(PictureFramePaintTarget, White, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(PictureFramePaintTarget2, White, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);

		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			DrawTextureToRendertarget(GetPlayerPaintData(Player).PaintTarget, Black, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		}
		DrawTextureToRendertarget(PlaceholderTarget, Black, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		DrawTextureToRendertarget(OpacityBrushTarget, Black, 0, 0, 1.0f, 1.0f, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
	}

	PlayerPaintData& GetPlayerPaintData(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetCody())
			return PlayerData[0];
		else
			return PlayerData[1];
	}

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	bool Initialized = false;
	void Initialize()
    {
		if(Initialized)
			return;

		Initialized = true;
		int PlayerTargetSize = 32;
		int PaperTargetSize = 512;
		
		InitMaterials();
		DrawCenteredMaterialDynamic = Material::CreateDynamicMaterialInstance(DrawCenteredMaterial);

		PaintColorBuffer = InitSwapBuffer(SimulationTargetSize, SimulationTargetSize, ETextureRenderTargetFormat::RTF_RGBA8);
		PaintVelocityBuffer = InitSwapBuffer(SimulationTargetSize, SimulationTargetSize, ETextureRenderTargetFormat::RTF_RGBA16f);

		PlaceholderTarget = InitRenderTarget(PlayerTargetSize, PlayerTargetSize, ETextureRenderTargetFormat::RTF_RGBA8);
		OpacityBrushTarget = InitRenderTarget(PlayerTargetSize, PlayerTargetSize, ETextureRenderTargetFormat::RTF_RGBA8);

		PaperPaintTarget1 = InitRenderTarget(PaperTargetSize, PaperTargetSize, ETextureRenderTargetFormat::RTF_RGBA8);
		PaperPaintTarget2 = InitRenderTarget(PaperTargetSize, PaperTargetSize, ETextureRenderTargetFormat::RTF_RGBA8);
		PictureFramePaintTarget = InitRenderTarget(PaperTargetSize, PaperTargetSize, ETextureRenderTargetFormat::RTF_RGBA8);
		PictureFramePaintTarget2 = InitRenderTarget(PaperTargetSize, PaperTargetSize, ETextureRenderTargetFormat::RTF_RGBA8);

		PaintMeshSurfaceMaterialDynamic = PaintMesh.StaticMeshComponent.CreateDynamicMaterialInstance(0);
		PaperPaintMaterialDynamic = Material::CreateDynamicMaterialInstance(PaperPaintMaterial);

		if(VelocityMesh != nullptr)
			VelocityMeshSurfaceMaterialDynamic = VelocityMesh.StaticMeshComponent.CreateDynamicMaterialInstance(0);
		ClearEverything();

		if(AlwaysPaint)
		{
			UStaticMeshComponent thing = nullptr;
			
			if(PaperMesh != nullptr)
				thing = UStaticMeshComponent::Get(PaperMesh);
			if(thing != nullptr)
				PaperMeshSurfaceMaterialDynamic = thing.CreateDynamicMaterialInstance(0);
		}
	}
	void InitPrinterPaper(UStaticMeshComponent PrinterPaperMesh)
	{
		Initialize();
		this.PrinterPaperMesh = PrinterPaperMesh;
		PrinterPaperMeshMaterial = PrinterPaperMesh.CreateDynamicMaterialInstance(0);
		PrinterPaperMeshMaterial.SetTextureParameterValue(n"Surface", PaperPaintTarget1);
	}

	FVector GetLocalPos(AActor GetLocal, FVector WorldPos, float Size)
	{
		auto a = GetLocal.GetActorTransform().InverseTransformPosition(WorldPos);
		return ((a / Size) + 1.0f) * 0.5f;
	}

	bool ShouldPaint(AActor Player, FVector Delta)
	{
		return Delta.Size() > 0 && UHazeMovementComponent::Get(Player).IsGrounded();
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Resolution", SimulationTargetSize);
		if(!Turbulence)
		{
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Damping", Damping);
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Diffusion", Diffusion);
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"FlowSpeed", FlowSpeed);
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Swap", 0.0f);
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", PaintVelocityBuffer.Target2);
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationColorTexture", PaintColorBuffer.Target2);
			SwapAndDraw(UpdateSimulationMaterialDynamic, PaintVelocityBuffer); // Advection only
			
		}
		else
		{
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Damping", Damping);
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Diffusion", Diffusion);
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"FlowSpeed", FlowSpeed);
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Swap", 1.0f);
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", PaintVelocityBuffer.Target2);
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationColorTexture", PaintColorBuffer.Target2);
			SwapAndDraw(UpdateSimulationMaterialDynamic, PaintVelocityBuffer); // Pressure

			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Swap", 2.0f);
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", PaintVelocityBuffer.Target2);
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationColorTexture", PaintColorBuffer.Target2);
			SwapAndDraw(UpdateSimulationMaterialDynamic, PaintVelocityBuffer); // Velocity
		}
		
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Swap", 3.0f);
		UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationTexture", PaintVelocityBuffer.Target2);
		UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"SimulationColorTexture", PaintColorBuffer.Target2);
		SwapAndDraw(UpdateSimulationMaterialDynamic, PaintColorBuffer); // Paint

		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			PlayerPaintData& d = GetPlayerPaintData(Player);
			// Smudging
			FVector Pos = GetLocalPos(PaintMesh, Player.GetActorLocation(), PaintObjectSize);
			FVector Delta = (Pos - d.LastPos) * 10.0f * SmugdeStrength;
			d.LastPos = Pos;
			if(AlwaysPaint)
			{
				bool PlayerIsStandingInPool = Pos.X > 0 && Pos.X < 1.0f && Pos.Y > 0 && Pos.Y < 1.0f;
				
				if(PlayerIsStandingInPool)
				{
					d.TempOpacity = 1.0f;
				}
				else
				{
					if(d.TempOpacity > 0)
					{
						d.TempOpacity -= DeltaTime / AlwaysPaintFadeTime;
					}
					if(d.TempOpacity <= 0)
					{
						// clear paint
						//ClearPlayerPaint(Player);
						d.TempOpacity = 0;
					}
					d.TempOpacity = FMath::Clamp(d.TempOpacity, 0.0f, 1.0f);
				}
			}
			else
			{	
				d.TempOpacity = 1.0f;
			}

			// Painting the players
			if(ShouldPaint(Player, Delta))
			{
				if(PaperMesh != nullptr)
					PaintOnPaper(Player.GetActorLocation(), d.PaintTarget, d.Opacity * d.TempOpacity, d.BrushSize * PaperPaintSize, d.bPlayerIsInPool);
				
				if((d.bPlayerIsInPool || AlwaysPaint))
				{
					//DrawTextureToRendertargetCentered(PaintVelocityBuffer.Target2, SmudgeTexture, Pos.X, Pos.Y, SmugdeSize, SmugdeSize, FLinearColor(Delta.X, Delta.Y, 0, 0), EBlendMode::BLEND_Additive);
					DrawTextureToRendertargetCentered_PS4Safe(PaintVelocityBuffer, SmudgeTexture, Pos.X, Pos.Y, SmugdeSize, SmugdeSize, FLinearColor(Delta.X, Delta.Y, 0, 0), EBlendMode::BLEND_Additive);
				}
			}
		}

		// Debugging
		if(VelocityMesh != nullptr)
			VelocityMeshSurfaceMaterialDynamic.SetTextureParameterValue(n"Surface", PaintVelocityBuffer.Target2);
			
		PaintMeshSurfaceMaterialDynamic.SetTextureParameterValue(n"Surface", PaintColorBuffer.Target2);
		PaintMeshSurfaceMaterialDynamic.SetTextureParameterValue(n"Simulation", PaintVelocityBuffer.Target2 );

		if(PaperMeshSurfaceMaterialDynamic != nullptr)
			PaperMeshSurfaceMaterialDynamic.SetTextureParameterValue(n"Surface", PaperPaintTarget);
	}

	void PaintOnPaper(FVector WorldPosition, UTextureRenderTarget2D TargetTexture, float Opacity, float CurrentPaintSize , bool bPlayerIsInPool)
	{
		float PlayerSampleSize = 0.01f;
		float MainTargetSize = 1.0f / PlayerSampleSize;
		FVector InversePos = (GetLocalPos(PaintMesh, WorldPosition, PaintObjectSize) * MainTargetSize) - 0.5;

		if((bPlayerIsInPool || AlwaysPaint) && PaintPlayer)
			DrawTextureToRendertarget(TargetTexture, PaintColorBuffer.Target2, -InversePos.X, -InversePos.Y, MainTargetSize, MainTargetSize, FLinearColor(1, 1, 1, 1), EBlendMode::BLEND_Opaque);
		
		// Swap
		UTextureRenderTarget2D LastPaperPaintTarget;
		if(PaperPaintTarget == PaperPaintTarget1)
		{
			PaperPaintTarget = PaperPaintTarget2;
			LastPaperPaintTarget = PaperPaintTarget1;
		}
		else
		{
			PaperPaintTarget = PaperPaintTarget1;
			LastPaperPaintTarget = PaperPaintTarget2;
		}

		FVector PaperLocalPos = GetLocalPos(PaperMesh, WorldPosition, PaperObjectSize);
		PaperLocalPos -= FVector::OneVector * CurrentPaintSize * 0.5f;
		
		// Set up brush parameters
		PaperPaintMaterialDynamic.SetVectorParameterValue(n"Target", FLinearColor(1, 1, 1, 1));
		PaperPaintMaterialDynamic.SetVectorParameterValue(n"Opacity", FLinearColor(Opacity, Opacity, Opacity, Opacity));
		// This is a rect in texture space (x, y, w, h)
		PaperPaintMaterialDynamic.SetVectorParameterValue(n"TextureTransform", 
			FLinearColor(PaperLocalPos.X, PaperLocalPos.Y, CurrentPaintSize, CurrentPaintSize));
		PaperPaintMaterialDynamic.SetTextureParameterValue(n"StampTexture", BlobTexture);
		PaperPaintMaterialDynamic.SetTextureParameterValue(n"BrushTexture", TargetTexture);
		
		PaperPaintMaterialDynamic.SetTextureParameterValue(n"PreviousFrame", LastPaperPaintTarget);
		PaperPaintMaterialDynamic.SetScalarParameterValue(n"SimulationSizeX", 512);
		PaperPaintMaterialDynamic.SetScalarParameterValue(n"SimulationSizeY", 512);
		PaperPaintMaterialDynamic.SetScalarParameterValue(n"SimulationSizeY", 512);
		
		Rendering::DrawMaterialToRenderTarget(PaperPaintTarget, PaperPaintMaterialDynamic);
		
	}
}