import Rice.RenderTextureDrawing.RenderTextureDrawing;
import Cake.Environment.GPUSimulations.Simulation;

USTRUCT()
struct TargetFoliageActor
{
	UPROPERTY()
	UStaticMesh Mesh;
	UPROPERTY()
	int NumberOfInstances;
}

USTRUCT()
struct FWitherSimulationArrayData
{
	UPROPERTY()
	bool bHasBeenPainted = false;
	UPROPERTY()
	FLinearColor Color = FLinearColor(0.f, 0.f, 0.f, 0.f);
}

USTRUCT()
struct FWitherSimulationArrayQueryData
{
	UPROPERTY()
	bool bWorldLocationWasInsideQueryArea = false;
	UPROPERTY()
	bool bHasBeenPainted = false;
	UPROPERTY()
	FLinearColor Color = FLinearColor(0.f, 0.f, 0.f, 0.f);
}

class APaintablePlane : ASimulation
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent)
    UStaticMeshComponent DebugMesh;
	default DebugMesh.SetStaticMesh(Asset("/Engine/BasicShapes/Plane.Plane"));
	
	UPROPERTY(Category = "Options")
	int CPUSideResolution = 32;
	UPROPERTY(Category = "Options")
	UTextureRenderTarget2D TargetRenderTexture = Asset("/Game/Blueprints/Environment/GpuSimulations/Wither/WitherTexture.WitherTexture");

	UPROPERTY(Category = "Options")
	bool LerpAndDrawTextureBlendsOnCPU = false;

	UPROPERTY(Category = "zzInternal", Transient, NotEditable)
	TArray<FWitherSimulationArrayData> CPUSideData;

	UPROPERTY(Category = "zzInternal")
	UMaterialParameterCollection WorldShaderParameters = Asset("/Game/MasterMaterials/WorldParameters/WorldParameters.WorldParameters");

	UPROPERTY(Category = "zzInternal")
	UTexture2D BlobTexture = Asset("/Game/Blueprints/Environment/GpuSimulations/PaintablePlane/WitherPaintBlob.WitherPaintBlob");

	UPROPERTY(Category = "zzInternal")
	UTexture2D BlobTexture_White = Asset("/Game/Blueprints/Environment/GpuSimulations/PaintablePlane/WitherPaintBlob_White.WitherPaintBlob_White");

	UPROPERTY(Category = "zzInternal")
	UTexture2D BlobTexture_Modulate = Asset("/Game/Blueprints/Environment/GpuSimulations/PaintablePlane/WitherPaintBlob_Modulate.WitherPaintBlob_Modulate");

	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic DebugPlaneMaterialDynamic;


	UPROPERTY(Category = "Debug|Test")
	bool DebugDrawAtTestLocation;

	UPROPERTY(Category = "Debug|Test")
	FLinearColor TestDrawColor = FLinearColor(1, 1, 1, 1);
	
	UPROPERTY(Category = "Debug|Test")
	FLinearColor TestDrawOpacity = FLinearColor(1, 1, 1, 1);
	
	UPROPERTY(Category = "Debug|Test")
	float TestDrawRadius = 500.0f;
	
	UPROPERTY(Category = "Debug|Test", meta = (MakeEditWidget))
	FVector TestDrawLocation;
	
	UPROPERTY(Category = "Debug|Test", meta = (MakeEditWidget))
	FVector TestQueryLocation;


	UPROPERTY(Category = "Debug|TestResult")
	bool SampleHasBeenPainted;

	UPROPERTY(Category = "Debug|TestResult")
	FLinearColor SampleColor;

	UPROPERTY(Category = "Debug|TestResult")
	bool SampleWorldLocationWasInsideQueryArea;

	UPROPERTY(Category = "Debug|Misc")
	bool DebugCPUSideData = false;
	UPROPERTY(Category = "Debug|Misc")
	bool DebugCPUSideDataTwo = false;
	
	UPROPERTY(Category = "Debug|Plane")
	bool DebugMeshVisible = true;

	UPROPERTY(Category = "Debug|Plane")
	bool DebugMeshHiddenInGame = true;

	UPROPERTY(Category = "Debug|Plane")
	UMaterialInterface DebugPlaneMaterial = Asset("/Game/Blueprints/Environment/GpuSimulations/PaintablePlane/DebugPaintablePlane.DebugPaintablePlane");

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerArea;
	default TriggerArea.SetCollisionProfileName(n"Trigger");
	default TriggerArea.BoxExtent = FVector(50.f, 50.f, 50.f);

	FLinearColor WitherPlaneTransform;
	
	int PlayersInArea = 0;
	bool bInvertDebugAlpha = false;
	bool bDebugAlphaIsWhite = false;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			PlayersInArea++;
			if(PlayersInArea == 1)
			{
				SetActorTickEnabled(true);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			PlayersInArea--;
			if(PlayersInArea == 0)
			{
				SetActorTickEnabled(false);
			}
		}
	}

	// Blueprint functions
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SetActorRotation(FRotator(0, 0, 0));
		TriggerArea.SetRelativeScale3D(FVector(Scale, Scale, Scale));
		DebugMesh.SetRelativeScale3D(FVector(Scale, Scale, Scale));
		DebugMesh.SetMaterial(0, DebugPlaneMaterial);
		DebugMesh.SetHiddenInGame(DebugMeshHiddenInGame);
		DebugMesh.SetVisibility(DebugMeshVisible);
		DebugMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DebugMesh.CastShadow = false;
		DebugMesh.SetCastShadow(false);
	}

    UFUNCTION()
	void Initialize()
    {
		SetActorTickEnabled(false);
		
		InitMaterials();
		if(TargetRenderTexture == nullptr)
			InitSwapBuffer(512,512, ETextureRenderTargetFormat::RTF_RGBA8);
		else
			InitSwapBuffer(TargetRenderTexture.SizeX, TargetRenderTexture.SizeY, ETextureRenderTargetFormat::RTF_RGBA8);
		
		// Clear
		if(TargetRenderTexture != nullptr)
		{
			if(DebugPlaneMaterial != nullptr)
			{
				DebugPlaneMaterialDynamic = DebugMesh.CreateDynamicMaterialInstance(0);
				DebugPlaneMaterialDynamic.SetTextureParameterValue(n"PaintablePlaneTexture", TargetRenderTexture);
			}
		}

		CPUSideData.SetNum(CPUSideResolution * CPUSideResolution);
	
		// Set Plane transform for material to read
		WitherPlaneTransform = FLinearColor(GetActorLocation().X - GetScale().X * 50, 
					 GetActorLocation().Y - GetScale().Y * 50, 
					 GetScale().X * 100, 
					 GetScale().Y * 100);
		Material::SetVectorParameterValue(WorldShaderParameters, n"WitherPlaneTransform", WitherPlaneTransform);

	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Initialize();
	}

	FVector2D GetCpuDataSize()const
	{
		FVector Origin;
		FVector Extends;
		GetActorBounds(false, Origin, Extends);
		return FVector2D(float(Extends.X) / float(CPUSideResolution), float(Extends.X) / float(CPUSideResolution));
	}


    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		// Set Plane transform for material to read
		WitherPlaneTransform = FLinearColor(GetActorLocation().X - GetScale().X * 50, 
					 GetActorLocation().Y - GetScale().Y * 50, 
					 GetScale().X * 100, 
					 GetScale().Y * 100);

		Material::SetVectorParameterValue(WorldShaderParameters, n"WitherPlaneTransform", WitherPlaneTransform);
		
		// Debug
		#if !RELEASE
		if(DebugDrawAtTestLocation)
		{
			LerpAndDrawTexture(GetActorTransform().TransformPosition(TestDrawLocation), TestDrawRadius, TestDrawColor, TestDrawOpacity, true); // Draw
			auto sample = QueryData(GetActorTransform().TransformPosition(TestQueryLocation)); // Sample
			SampleColor = sample.Color;
			SampleHasBeenPainted = sample.bHasBeenPainted;
			SampleWorldLocationWasInsideQueryArea = sample.bWorldLocationWasInsideQueryArea;
		}

		if(DebugCPUSideDataTwo)
		{
			for(int i = 0; i < CPUSideResolution * CPUSideResolution; i++)
			{
				const FVector WorldPosition = ArrayLocationToWorldLocation(i);
				FLinearColor Color = CPUSideData[i].Color;
				Color.A = bInvertDebugAlpha ? 1 - Color.A : Color.A;
				if(bDebugAlphaIsWhite && Color.A > 0.5f)
					Color = FLinearColor(1.f, 1.f, 1.f, 1.f);
		
				//Color.A = 1.0f;
				//if(CPUSideData[i].bHasBeenPainted)
				//	System::DrawDebugCircle(WorldPosition + (FVector::UpVector * 80), 32.f, 32, Color, ZAxis = FVector::ForwardVector);
				
				//if(WorldPosition.Distance(Game::Cody.GetActorLocation()) < 1000 || 
				//   WorldPosition.Distance(Game::May.GetActorLocation())  < 1000)
				System::DrawDebugLine(WorldPosition, WorldPosition + FVector(0, 0, 800), Color, 0, 5);	
			}
		}
		#endif
    }
	
	void DebugDrawCpuData(FVector CenterLocation, FVector Extends, bool bIsSelected) const
	{
#if !RELEASE
		TArray<int> Box;
		GetIndicesInRect(CenterLocation, Extends, Box);
		DebugDrawCpuData(Box, bIsSelected, CenterLocation.Z);
#endif
	}

	void DebugDrawCpuData(TArray<int> Box, bool bIsSelected, float Zheight) const
	{
#if !RELEASE
		const int MaxAmount = Box.Num();
		if(MaxAmount <= 0)
			return;

		for(int i = 0; i < MaxAmount; i++)
		{
			FLinearColor Color = CPUSideData[Box[i]].Color;
			Color.A = bInvertDebugAlpha ? 1 - Color.A : Color.A;
			if(bDebugAlphaIsWhite && Color.A > 0.5f)
				Color = FLinearColor(1.f, 1.f, 1.f, 1.f);

			FVector WorldPosition = ArrayLocationToWorldLocation(Box[i]);
			WorldPosition.Z = Zheight;
		
			if(bIsSelected)
			{
				if(CPUSideData[i].bHasBeenPainted)
					System::DrawDebugCircle(WorldPosition + (FVector::UpVector * 80), 32.f, 32, Color, ZAxis = FVector::ForwardVector, Thickness = 10);
				else
					System::DrawDebugLine(WorldPosition, WorldPosition + FVector(0, 0, 600), Color, 0, 10);	
			}
			else
			{
				if(CPUSideData[i].bHasBeenPainted)
					System::DrawDebugCircle(WorldPosition + (FVector::UpVector * 80), 32.f, 32, Color, ZAxis = FVector::ForwardVector);
				else
					System::DrawDebugLine(WorldPosition, WorldPosition + FVector(0, 0, 600), Color, 0, 10);	
			}
			
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{

	}
	
    UFUNCTION(CallInEditor)
	void Clear(FLinearColor ClearColor = FLinearColor(0, 0, 0, 1), bool bHasBeenPainted = false)
	{
		Rendering::ClearRenderTarget2D(SimulationBuffer.Target1, 	ClearColor);
		Rendering::ClearRenderTarget2D(SimulationBuffer.Target2, 	ClearColor);
		if(TargetRenderTexture != nullptr)
			Rendering::ClearRenderTarget2D(TargetRenderTexture, 		ClearColor);


		for(auto thing : CPUSideData)
		{
			thing.Color = ClearColor;
			thing.bHasBeenPainted = bHasBeenPainted;
		}
	}
	
    UFUNCTION()
	void LerpAndDrawTexture(FVector WorldLocation, float WorldRadius, FLinearColor TargetColor, FLinearColor Opacity, 
	bool bHasBeenPaintedStatus = true,  UTexture2D TextureOverride = nullptr, bool EditCPUSideData = true, 
	FLinearColor CPUSideOpacityMultiplier = FLinearColor(1,1,1,1), bool CPUsideCircle = true, float CPUSideRadiusMultiplier = 1.0f)
	{
		float TextureRadius = WorldRadiusToTextureRadius(WorldRadius);
		const FVector TexturePosition = WorldLocationToTextureLocation(WorldLocation);
		LerpAndDrawTextureTS(TexturePosition, TextureRadius, TargetColor, Opacity, bHasBeenPaintedStatus, TextureOverride, EditCPUSideData, CPUSideOpacityMultiplier, CPUsideCircle, CPUSideRadiusMultiplier);
	}

	// Functions for interacting with this bp
	UFUNCTION()
	void LerpAndDrawTextureTS(FVector TextureLocationIn, float TextureRadiusIn, FLinearColor TargetColor, FLinearColor Opacity, 
	bool bHasBeenPaintedStatus = true, UTexture2D TextureOverride = nullptr, bool EditCPUSideData = true, 
	FLinearColor CPUSideOpacityMultiplier = FLinearColor(1,1,1,1), bool CPUsideCircle = true, float CPUSideRadiusMultiplier = 1.0f)
	{
		float TextureRadius = TextureRadiusIn * 2.0f;
		FVector TextureLocation = TextureLocationIn - TextureRadius * 0.5f;
		// Set up brush parameters
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"Target", TargetColor);
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"Opacity", Opacity);
		// This is a rect in texture space (x, y, w, h)
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"TextureTransform", 
			FLinearColor(TextureLocation.X, TextureLocation.Y, TextureRadius, TextureRadius));

		if(TextureOverride != nullptr)
		{
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"StampTexture", TextureOverride);
		}
		else
		{
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"StampTexture", BlobTexture);
		}	

		// Draw with our brush
		UpdateSwapBuffer();
		
		// Copy target to the output texture for use in shaders
		if(TargetRenderTexture != nullptr)
			CopyRenderTarget(SimulationBuffer.Target2, TargetRenderTexture, CopyTextureMaterialDynamic);
		
		if(EditCPUSideData)
		{
			TArray<int> Box;
			if(CPUsideCircle)
				GetIndicesInCircleTS(TextureLocationIn, TextureRadiusIn * CPUSideRadiusMultiplier, Box);
			else
				GetIndicesInRectTS(TextureLocationIn, FVector(TextureRadiusIn * CPUSideRadiusMultiplier, TextureRadiusIn * CPUSideRadiusMultiplier, TextureRadiusIn * CPUSideRadiusMultiplier), Box);

			for(int i = 0; i < Box.Num(); i++)
			{
				FWitherSimulationArrayData& Index = CPUSideData[Box[i]];
				Index.bHasBeenPainted = bHasBeenPaintedStatus;
				
				if(LerpAndDrawTextureBlendsOnCPU)
				{
					Index.Color.R = FMath::Lerp(Index.Color.R, TargetColor.R, FMath::Clamp(Opacity.R * CPUSideOpacityMultiplier.R * Time::GlobalWorldDeltaSeconds, 0.0f, 1.0f));
					Index.Color.G = FMath::Lerp(Index.Color.G, TargetColor.G, FMath::Clamp(Opacity.G * CPUSideOpacityMultiplier.G * Time::GlobalWorldDeltaSeconds, 0.0f, 1.0f));
					Index.Color.B = FMath::Lerp(Index.Color.B, TargetColor.B, FMath::Clamp(Opacity.B * CPUSideOpacityMultiplier.B * Time::GlobalWorldDeltaSeconds, 0.0f, 1.0f));
					Index.Color.A = FMath::Lerp(Index.Color.A, TargetColor.A, FMath::Clamp(Opacity.A * CPUSideOpacityMultiplier.A * Time::GlobalWorldDeltaSeconds, 0.0f, 1.0f));

				}
				else
				{
					Index.Color.R = Opacity.R > 0.5 ? TargetColor.R : Index.Color.R;
					Index.Color.G = Opacity.G > 0.5 ? TargetColor.G : Index.Color.G;
					Index.Color.B = Opacity.B > 0.5 ? TargetColor.B : Index.Color.B;
					Index.Color.A = Opacity.A > 0.5 ? TargetColor.A : Index.Color.A;
				}

				
				// Debug
				//#if !RELEASE
				//	if(DebugCPUSideData)
				//		System::DrawDebugCircle(ArrayLocationToWorldLocation(Box[i]) + (FVector::UpVector * 20), 32.f, 128, ZAxis = FVector::ForwardVector);
				//#endif
				
			}
		}
	}

    UFUNCTION(BlueprintPure)
	FWitherSimulationArrayQueryData QueryDataTS(FVector TextureLocation) const
	{
		FWitherSimulationArrayQueryData FinalizedData;
		const int ArrayLocation = TextureLocationToArrayLocation(TextureLocation);
		if(ArrayLocationIsValid(ArrayLocation))
		{
			FinalizedData.bWorldLocationWasInsideQueryArea = true;
			FinalizedData.bHasBeenPainted = CPUSideData[ArrayLocation].bHasBeenPainted;
			FinalizedData.Color = CPUSideData[ArrayLocation].Color;
		}
		return FinalizedData;
	}
	
    UFUNCTION(BlueprintPure)
	FWitherSimulationArrayQueryData QueryData(FVector WorldLocation) const
	{
		const FVector TexturePosition = WorldLocationToTextureLocation(WorldLocation);
		return QueryDataTS(TexturePosition);
	}
	
	float GetPaintedPercentage(FVector CenterLocation, FVector Extends) const
	{
		TArray<int> Box;
		GetIndicesInRect(CenterLocation, Extends, Box);
		return GetPaintedPercentage(Box);
	}

	float GetPaintedPercentage(TArray<int> IndiciesBox) const
	{
		const int MaxAmount = IndiciesBox.Num();

		if(MaxAmount <= 0)
			return 0.f;

		int PaintedAmount = 0;
		for(int i = 0; i < MaxAmount; i++)
		{
			if(CPUSideData[IndiciesBox[i]].bHasBeenPainted)
				PaintedAmount++;
		}

		return float(PaintedAmount) / float(MaxAmount);
	}


	// Utility functions

	int GetArraySize() const
	{
		return FMath::Square(CPUSideResolution);
	}

	bool ArrayLocationIsValid(int Index) const
	{
		return Index >= 0 && Index < CPUSideData.Num();
	}

	FVector WorldLocationToTextureLocation(FVector WorldLocation) const
	{
		FVector TexturePosition = (GetActorTransform().InverseTransformPosition(WorldLocation)); 
		TexturePosition /= 100.0f * Scale; // 100 is the size of the plane mesh unscaled
		TexturePosition += FVector(0.5f, 0.5f, 0.5f); // Textures are between 0, 1 not -0.5, 0.5
		return TexturePosition;
	}

	FVector TextureLocationToWorldLocation(FVector TextureLocation) const
	{
		FVector WorldPosition = TextureLocation - FVector(0.5f, 0.5f, 0.5f);
		WorldPosition.Z = 0;
		WorldPosition *= 100 * Scale;
		WorldPosition = (GetActorTransform().TransformPosition(WorldPosition)); 
		return WorldPosition;
	}

	UPROPERTY()
	float Scale = 1.0f;
	FVector GetScale() const
	{
		return GetActorScale3D() * Scale;
	}

	FVector WorldExtentsToTextureExtents(FVector WorldExtents) const
	{
		return (WorldExtents / GetScale()) * 0.01f;
	}

	float WorldRadiusToTextureRadius(float WorldRadius) const
	{
		float AverageWidth = (GetScale().X + GetScale().Y) * 0.5f;
		return (WorldRadius / AverageWidth) * 0.01f;
	}

	float TextureRadiusToWorldRadius(float TextureRadius) const
	{
		float AverageWidth = (GetScale().X + GetScale().Y) * 0.5f;
		return TextureRadius * AverageWidth * 100;
	}

	int WorldLocationToArrayLocation(FVector WorldLocation) const
	{
		const FVector TextureLocation = WorldLocationToTextureLocation(WorldLocation);
		return TextureLocationToArrayLocation(TextureLocation);
	}

	UFUNCTION()
	FVector ArrayLocationToWorldLocation(int ArrayPosition) const
	{
		float X = ArrayPosition % CPUSideResolution;
		float Y = ArrayPosition / CPUSideResolution;

		// get local space position
		X -= CPUSideResolution / 2;
		Y -= CPUSideResolution / 2;

		// offset by half so the debug line shows up in the middle of the pixel
		X += 0.5;
		Y += 0.5;

		X /= CPUSideResolution;
		Y /= CPUSideResolution;
			
		X *= 100 * Scale;
		Y *= 100 * Scale;

		return (GetActorTransform().TransformPosition(FVector(X, Y, 0))); 
	}

	FVector ArrayLocationToTextureLocation(int ArrayPosition) const
	{
		FVector Result = FVector(0, 0, 0);
		int X = (ArrayPosition % CPUSideResolution);
		int Y = (ArrayPosition / CPUSideResolution);
		Result.X = (float(X) + 0.5f) / float(CPUSideResolution);
		Result.Y = (float(Y) + 0.5f) / float(CPUSideResolution);
		return Result;
	}

	int TextureLocationToArrayLocation(FVector TexturePosition) const
	{
		const int XX = int(TexturePosition.X * float(CPUSideResolution));
		const int YY = int(TexturePosition.Y * float(CPUSideResolution));

		return XX + (YY * CPUSideResolution);
	}

	UFUNCTION()
	void GetIndicesInRect(FVector WorldPosition, FVector WorldExtents, TArray<int>& OutResult) const
	{
		const FVector TexturePosition = WorldLocationToTextureLocation(WorldPosition);
		FVector TextureExtents = WorldExtentsToTextureExtents(WorldExtents);
		GetIndicesInRectTS(TexturePosition, TextureExtents, OutResult);
	}

	// texture-space version is the most pure.
	void GetIndicesInRectTS(FVector TexturePosition, FVector TextureExtentsIn, TArray<int>& OutResult) const
	{
		FVector TextureExtents = TextureExtentsIn;
		// Swap X and Y
		float Temp = TextureExtents.X;
		TextureExtents.X = TextureExtents.Y;
		TextureExtents.Y = Temp;

		const float stride = CPUSideResolution;

		// Make the correct conversion here, Tyko
		const float RadiusX = FMath::CeilToInt(TextureExtents.X * stride)+1;
		const float RadiusY = FMath::CeilToInt(TextureExtents.Y * stride)+1;
		const float DiameterX = FMath::CeilToInt(TextureExtents.X * stride * 2.0f)+2;
		const float DiameterY = FMath::CeilToInt(TextureExtents.Y * stride * 2.0f)+2;
		
		const float XX = FMath::CeilToInt(TexturePosition.X * stride);
		const float YY = FMath::CeilToInt(TexturePosition.Y * stride);
		
		// Box that's slightly larger than the real box
		OutResult.Reserve(DiameterX * DiameterY);
		for(int x = 0; x < DiameterX; x++)
		{
			int xOffset = (x - RadiusX);
			if((YY + xOffset) < 0 || (YY + xOffset) > stride - 1) // we are off the side of the array
				continue;
			for(int y = 0; y < DiameterY; y++)
			{
				int yOffset = y - RadiusY;
				if((XX + yOffset) < 0 || (XX + yOffset) > stride - 1) // we are off the side of the array
					continue;
				
				const int center = XX + (YY * stride);
				const int IndexToAdd = (center + yOffset) + xOffset * stride;
				const FVector IndexWoldPos = ArrayLocationToTextureLocation(IndexToAdd);
				float OffsetX = TexturePosition.X - IndexWoldPos.X;
				float OffsetY = TexturePosition.Y - IndexWoldPos.Y;

				// Filter points that are exactly inside the box here
				if(FMath::Abs(OffsetX) < FMath::Abs(TextureExtents.Y) &&
				   FMath::Abs(OffsetY) < FMath::Abs(TextureExtents.X))
				{
					OutResult.Add(IndexToAdd);
				}
			}
		}
	}

	UFUNCTION()
	void GetIndicesInCircleBP(FVector WorldPosition, float WorldRadius, TArray<int>& OutResult) const
	{
		GetIndicesInCircle(WorldPosition, WorldRadius, OutResult);
	}

	void GetIndicesInCircle(FVector WorldPosition, float WorldRadius, TArray<int>& OutResult) const
	{
		const FVector TexturePosition = WorldLocationToTextureLocation(WorldPosition);
		const float TextureRadius = WorldRadiusToTextureRadius(WorldRadius);
		GetIndicesInCircleTS(TexturePosition, TextureRadius, OutResult);
	}

	void GetIndicesInCircle(FVector WorldPosition, float WorldRadius, float DebugTime, TArray<int>& OutResult) const
	{
		if(DebugTime > 0)
			System::DrawDebugCircle(WorldPosition, WorldRadius, 32, ZAxis = FVector::ForwardVector, Duration = DebugTime);

		GetIndicesInCircle(WorldPosition, WorldRadius, OutResult);
	}

	// texture-space version is the most pure.
	void GetIndicesInCircleTS(FVector TexturePosition, float TextureRadius, TArray<int>& OutResult) const
	{
		FVector TexPos = FVector(TexturePosition.X, TexturePosition.Y, 0);

		const int RadiusX = FMath::RoundToInt((float(CPUSideResolution) * TextureRadius))+1;	
		const int RadiusY = FMath::RoundToInt((float(CPUSideResolution) * TextureRadius))+1;	
		OutResult.Reserve((RadiusX * 2 + 1) * (RadiusY * 2 + 1));
		
		const int stride = CPUSideResolution;
		const int XX = (TexPos.X) * CPUSideResolution;
		const int YY = (TexPos.Y) * CPUSideResolution;
		const float center = XX + (YY * stride);

		for(int x = 0; x < (RadiusX * 2 + 1); x++)
		{
			const int xOffset = (x - RadiusX);
			if((YY + xOffset) < 0 || (YY + xOffset) > stride - 1) // we are off the side of the array
				continue;

			for(int y = 0; y < (RadiusY * 2 + 1); y++)
			{
				const int yOffset = y - RadiusY;
				if((XX + yOffset) < 0 || (XX + yOffset) > stride - 1) // we are off the side of the array
					continue;
				
				const int IndexToAdd = (center + yOffset) + xOffset * stride;
				// This may break if ArrayLocationToTextureLocation is overridden.
				FVector IndexTexture = ArrayLocationToTextureLocation(IndexToAdd);
				IndexTexture *= FVector(1, 1, 0);
				TexPos *= FVector(1, 1, 0);
				float dst1 = TexPos.Distance(IndexTexture);
				float dst2 = TextureRadius;
				if(dst1 > dst2)
					continue;

				OutResult.Add(IndexToAdd);
			}
		}
	}
}