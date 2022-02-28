
import Cake.Environment.GPUSimulations.Simulation;
import Cake.Environment.GPUSimulations.PaintablePlane;

class ABallPitBallCollider : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComponent;
	default BoxComponent.BoxExtent = FVector(100, 100, 100);
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComponent;

	UPROPERTY()
	bool Enabled = true;

	UPROPERTY()
	bool Radial;

	UPROPERTY(meta = (ClampMin = 0.0, ClampMax = 1.0))
	float PushStrength = 0.25f;

	UPROPERTY(meta = (ClampMin = 0.0, ClampMax = 1.0))
	float LiftStrength = 0.25f;

	UPROPERTY()
	UTexture2D MaskTexture;
	
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		
		//SetActorRotation(FRotator(0, GetActorRotation().Yaw, 0));
		//#if EDITOR
		//	if(!Editor::IsCooking() && Level.IsVisible())
		//	{
		//		if(Enabled)
		//			Cast<ABallPitCollision>(Gameplay::GetActorOfClass(ABallPitCollision::StaticClass())).Initialize();
		//	}
		//#endif
	}

	//UFUNCTION(CallInEditor)
    //void UpdateCollision()
    //{
	//	#if EDITOR
	//		if(Enabled)
	//			Cast<ABallPitCollision>(Gameplay::GetActorOfClass(ABallPitCollision::StaticClass())).Initialize();
	//	#endif
	//}
}

class ABallPitCollision : APaintablePlane
{
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		//Super::ConstructionScript();
	}

    UFUNCTION(CallInEditor)
	void UpdateWaterSurface()
	{
		//Initialize();
	}

    UFUNCTION()
	void Initialize()
	{
		//Super::Initialize();
		//TArray<ABallPitBallCollider> Colliders = TArray<ABallPitBallCollider>();
		//TArray<AActor> ActorColliders = TArray<AActor>();
		//Gameplay::GetAllActorsOfClass(ABallPitBallCollider::StaticClass(), ActorColliders);
		//for(AActor a : ActorColliders)
		//{
		//	Colliders.Add(Cast<ABallPitBallCollider>(a));
		//}
//
		//Clear(FLinearColor(0.5, 0.5, 0.0, 0));
		//for(ABallPitBallCollider Collider : Colliders)
		//{
		//	if(!Collider.Enabled)
		//		continue;
//
		//	float rot = Collider.GetActorRotation().Yaw;
		//	DrawBallCollision(Collider.GetActorLocation(), 
		//					  Collider.BoxComponent.BoxExtent.X * Collider.GetActorScale3D().X, 
		//					  Collider.BoxComponent.BoxExtent.Y * Collider.GetActorScale3D().Y, 
		//					  rot, Collider.MaskTexture, Collider.Radial, Collider.PushStrength, Collider.LiftStrength);
		//}
//
		//UpdateSwapBuffer();
		//CopyRenderTarget(SimulationBuffer.Target1, TargetRenderTexture, CopyTextureMaterialDynamic);
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		//Initialize();
	}

	UFUNCTION()
	void DrawBallCollision(FVector WorldLocation, float Width, float Height, float Rotation, UTexture2D MaskTexture, bool Radial, float PushStrength, float LiftStrength)
	{
		//float WidthTS = (Width / GetActorScale3D().X) * 0.01f * 2.0f;
		//float HeightTS = (Height / GetActorScale3D().Y) * 0.01f * 2.0f;
		//FVector LocationTS = WorldLocationToTextureLocation(WorldLocation);
		//LocationTS = LocationTS - FVector(WidthTS, HeightTS, 0) * 0.5f;
//
		//// Set up brush parameters
//
		//// This is a rect in texture space (x, y, w, h)
		//UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"TextureTransform", 
		//	FLinearColor(LocationTS.X, LocationTS.Y, WidthTS, HeightTS));
//
		//UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Angle", Rotation);
		//UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Radial", Radial ? 1.0f : 0.0f);
		//UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"PushStrength", PushStrength);
		//UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"LiftStrength", LiftStrength);
//
		//UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"MaskTexture", MaskTexture);
//
		//// Draw with our brush
		//UpdateSwapBuffer();
		//
		//// Copy target to the output texture for use in shaders
		//CopyRenderTarget(SimulationBuffer.Target1, TargetRenderTexture, CopyTextureMaterialDynamic);
	}
}