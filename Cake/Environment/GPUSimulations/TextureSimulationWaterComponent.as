import Cake.Environment.GPUSimulations.TextureSimulationComponent;

struct FLandscapeSamplingStruct
{
	ULandscapeComponent LandscapeComponent;
	int FlowXChannel;
	int FlowYChannel;
};

class UTextureSimulationWaterComponent : UTextureSimulationComponent
{
	UPROPERTY(Category = "Input")
	ALandscape TargetLandscape;

	ALandscape LastTargetLandscape;

	UPROPERTY(Category = "Input")
	AStaticMeshActor TestMesh;

	UPROPERTY(Category = "zzInternal")
	UMaterialInstanceDynamic TestMeshMaterialDynamic;

	UPROPERTY(Category = "zzInternal")
	TArray<ULandscapeComponent> LandscapeChunks;

	UPROPERTY(Category = "zzInternal")
	ULandscapeLayerInfoObject FlowXLandscapeLayer = Asset("/Game/MasterMaterials/LandscapeGenericLayers/FlowX.FlowX");

	UPROPERTY(Category = "zzInternal")
	ULandscapeLayerInfoObject FlowYLandscapeLayer = Asset("/Game/MasterMaterials/LandscapeGenericLayers/FlowY.FlowY");

	UPROPERTY(Category = "zzInternal")
	float BoatStrength = 1.0f;

	FLandscapeSamplingStruct GetClosestLandscapeComponent(FVector Location)
	{
		ULandscapeComponent CurrentClosest;
		float Dist = MAX_flt;
		for (auto t : LandscapeChunks)
		{
			float dist = t.GetWorldLocation().Distance(Location);
			if(dist < Dist)
			{
				Dist = dist;
				CurrentClosest = t;
			}
		}

		FLandscapeSamplingStruct Result;
		Result.LandscapeComponent = CurrentClosest;
		for(int i = 0; i < CurrentClosest.WeightmapLayerAllocations.Num(); i++ )
		{
			auto t = CurrentClosest.WeightmapLayerAllocations[i].LayerInfo;
			if(t == FlowXLandscapeLayer)
			{
				Result.FlowXChannel = CurrentClosest.WeightmapLayerAllocations[i].WeightmapTextureChannel;
			}
			else if(t == FlowYLandscapeLayer)
			{
				Result.FlowYChannel = CurrentClosest.WeightmapLayerAllocations[i].WeightmapTextureChannel;
			}
		}
		
		return Result;
	}

	TArray<FLandscapeSamplingStruct> GetClosestFourLandscapeComponents(FVector Location)
	{
		auto t = TargetLandscape.GetActorTransform();

		FVector ObjectRight = FVector(1, 0, 0);
		FVector ObjectForward = FVector(0, 1, 0);

		FVector LandscapeRight = t.TransformVector(ObjectRight)*63;
		FVector LandscapeForward = t.TransformVector(ObjectForward)*63;

		TArray<FLandscapeSamplingStruct> Result;
		Result.Add(GetClosestLandscapeComponent(Location + FVector(0, 0, 0)));
		Result.Add(GetClosestLandscapeComponent(Location + LandscapeRight));
		Result.Add(GetClosestLandscapeComponent(Location + LandscapeForward));
		Result.Add(GetClosestLandscapeComponent(Location + LandscapeRight + LandscapeForward));

		return Result;
	}

	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		UTextureSimulationComponent::BeginPlay();
		LastTargetLandscape = TargetLandscape;
		Initialize();
	}

	void Initialize()
	{
		if(TargetLandscape == nullptr)
			return;

		LandscapeChunks.Empty();
		
		for (auto t : TargetLandscape.GetComponentsByClass(ULandscapeComponent::StaticClass()))
		{
			LandscapeChunks.Add(Cast<ULandscapeComponent>(t));
		}
	}

	FLinearColor ChannelMaskFromIndex(int index)
	{
		if(index == 0)
			return FLinearColor(1,0,0,0);
		if(index == 1)
			return FLinearColor(0,1,0,0);
		if(index == 2)
			return FLinearColor(0,0,1,0);
		if(index == 3)
			return FLinearColor(0,0,0,1);

		return FLinearColor(0,0,0,0);
	}

	UPROPERTY(Category = "System")
	FVector LastLocation;
	
	UPROPERTY(Category = "Input")
	float BoatRadius = 0.25f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		if(LastTargetLandscape != TargetLandscape)
		{
			LastTargetLandscape = TargetLandscape;
			Initialize();
		}

		if(TargetLandscape == nullptr)
			return;
			
		UTextureSimulationComponent::Tick(DeltaTime);

		DrawCircleToSimulation(0.5, 0.5, BoatRadius, FLinearColor(1, 0, 0, 0), FLinearColor(1 * BoatStrength, 0, 0, 0));
		
		FVector DeltaLocation = LastLocation - Owner.GetActorLocation();
		LastLocation = Owner.GetActorLocation();
		
		auto t = TargetLandscape.GetActorTransform();

		FVector SampleLocation = Owner.GetActorLocation() - FVector(3000, 3000, 0);
		FVector ObjectRight = FVector(1, 0, 0);
		FVector ObjectForward = FVector(0, 1, 0);

		FVector LandscapeRight = t.InverseTransformVector(ObjectRight) * 80;
		FVector LandscapeLeft = t.InverseTransformVector(ObjectForward) * 80;

		FVector LandscapeLocalLocation = t.InverseTransformPosition(SampleLocation);
		FVector LandscapeIndexLocation = LandscapeLocalLocation;
		float LandscapeChunkSize = 63;

		FVector ChunkLocalPosition;
		ChunkLocalPosition.X = (LandscapeIndexLocation.X / LandscapeChunkSize + 500) % 1.0;
		ChunkLocalPosition.Y = (LandscapeIndexLocation.Y / LandscapeChunkSize + 500) % 1.0;
		ChunkLocalPosition.Z = 0;

		LandscapeIndexLocation.X = FMath::FloorToFloat(LandscapeIndexLocation.X / LandscapeChunkSize) * LandscapeChunkSize;
		LandscapeIndexLocation.Y = FMath::FloorToFloat(LandscapeIndexLocation.Y / LandscapeChunkSize) * LandscapeChunkSize;
		LandscapeIndexLocation.Z = 0;
		LandscapeIndexLocation = t.TransformPosition(LandscapeIndexLocation);

		auto Chunks = GetClosestFourLandscapeComponents(LandscapeIndexLocation);

		for(int i = 0; i < 4; i++ )
		{
			auto WeightMapTexture = Chunks[i].LandscapeComponent.WeightmapTextures[0];
			
			UpdateSimulationMaterialDynamic.SetTextureParameterValue(FName("FlowmapGrid" + i), WeightMapTexture);
			UpdateSimulationMaterialDynamic.SetVectorParameterValue(FName("FlowmapGrid" + i + "XMask"), ChannelMaskFromIndex(Chunks[i].FlowXChannel));
			UpdateSimulationMaterialDynamic.SetVectorParameterValue(FName("FlowmapGrid" + i + "YMask"), ChannelMaskFromIndex(Chunks[i].FlowYChannel));
		}
		
		float ScaleX = 6000;
		float ScaleY = 6000;
		Material::SetVectorParameterValue(WorldShaderParameters, n"LandscapeSimulationTransformA", FLinearColor(LandscapeLocalLocation.X, LandscapeLocalLocation.Y, ScaleX / 100, ScaleY / 100));

		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"LandscapeSimulationTransformA", FLinearColor(ChunkLocalPosition.X, ChunkLocalPosition.Y, ScaleX / 6300, ScaleY / 6300));
		

		// float2 offset for when the object moves.
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"DeltaPositionX", DeltaLocation.X/6300);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"DeltaPositionY", DeltaLocation.Y/6300);
		
		// Set landscape useability vector
		Material::SetVectorParameterValue(WorldShaderParameters, n"LandscapePivot", FLinearColor(
			TargetLandscape.GetActorLocation().X, 
			TargetLandscape.GetActorLocation().Y, 
			TargetLandscape.GetActorLocation().Z, ScaleY));

	}
}